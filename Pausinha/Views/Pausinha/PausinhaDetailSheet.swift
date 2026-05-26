//
//  PausinhaDetailSheet.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//
//  Sheet de detalhes de uma pausinha ativa.
//  Exibe avatares empilhados grandes, título, timer e botões de entrar/sair.
//

import SwiftUI

struct PausinhaDetailSheet: View {
    let group: PausinhaGroup

    /// userID do usuário logado (para lógica de entrar/sair/encerrar)
    let currentUserID: String

    @Environment(PausinhaService.self) private var pausinhaService
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var showCloseConfirmation = false
    @State private var errorMessage: String?
    @State private var timeRemaining: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isParticipant: Bool {
        group.participantIDs.contains(currentUserID)
    }

    private var isCreator: Bool {
        group.creatorID == currentUserID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // Avatares grandes empilhados no topo
                    avatarsSection

                    // Timer central
                    timerSection

                    // Botão principal: Entrar ou Sair
                    actionButton

                    // Encerrar (apenas o criador)
                    if isCreator {
                        closeButton
                    }

                    // Erro
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationTitle(group.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .accessibilityLabel("Fechar")
                }
            }
            .onAppear { updateTime() }
            .onReceive(timer) { _ in updateTime() }
            .confirmationDialog(
                "Encerrar pausinha?",
                isPresented: $showCloseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Encerrar", role: .destructive) {
                    Task { await closePausinha() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Todos os participantes serão removidos e a pausinha será encerrada.")
            }
        }
    }

    // MARK: - Subviews

    private var avatarsSection: some View {
        VStack(spacing: 12) {
            StackedAvatarsView(
                participants: group.participantIDs.map {
                    ParticipantAvatar(userID: $0, name: String($0.prefix(1)), imageData: nil)
                },
                size: 56,
                maxVisible: 5
            )

            Text("\(group.currentParticipantCount) \(group.currentParticipantCount == 1 ? "pessoa" : "pessoas") na pausa")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var timerSection: some View {
        VStack(spacing: 6) {
            if group.isOverTime {
                Text("⏰ Tempo extra!")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("O tempo estipulado acabou, mas a sala ainda está aberta.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(formatTimeInterval(timeRemaining))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                Text("restantes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            Task { await toggleParticipation() }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: isParticipant ? "rectangle.portrait.and.arrow.right" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isParticipant ? "Sair da pausa" : "Entrar na pausa")
                        .font(.headline)
                }
            }
            .foregroundColor(isParticipant ? .primary : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isParticipant ? Color(UIColor.systemGray5) : Color.accentColor)
            )
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isParticipant)
    }

    private var closeButton: some View {
        Button(action: { showCloseConfirmation = true }) {
            Text("Encerrar pausinha")
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .disabled(isLoading)
    }

    // MARK: - Actions

    @MainActor
    private func toggleParticipation() async {
        isLoading = true
        errorMessage = nil

        do {
            if isParticipant {
                // Criador não pode sair — deve encerrar
                if isCreator {
                    showCloseConfirmation = true
                    isLoading = false
                    return
                }
                try await pausinhaService.leavePausinha(group, userID: currentUserID)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } else {
                // Sair de qualquer outra pausinha ativa antes de entrar
                for active in pausinhaService.activePausinhas where active.id != group.id {
                    if active.participantIDs.contains(currentUserID) {
                        try await pausinhaService.leavePausinha(active, userID: currentUserID)
                    }
                }
                try await pausinhaService.joinPausinha(group, userID: currentUserID)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func closePausinha() async {
        isLoading = true
        errorMessage = nil

        do {
            try await pausinhaService.closePausinha(group, requestingUserID: currentUserID)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func updateTime() {
        timeRemaining = max(0, group.expiresAt.timeIntervalSinceNow)
    }
}

// MARK: - Preview

#Preview {
    PausinhaDetailSheet(
        group: PausinhaGroup(
            title: "Café",
            icon: "☕️",
            institutionID: "inst1",
            creatorID: "user1",
            participantIDs: ["user1", "user2", "user3"],
            expiresAt: Date().addingTimeInterval(10 * 60)
        ),
        currentUserID: "user2"
    )
    .environment(PausinhaService())
}
