//
//  PausinhaCardView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//
//  Card de pausinha ATIVA exibido na Home.
//  Exibe título, avatares empilhados, contagem de participantes e tempo restante.
//

import SwiftUI

struct PausinhaCardView: View {
    let group: PausinhaGroup
    let onTap: () -> Void

    // Tempo restante atualizado a cada segundo
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {

                // Ícone da Pausinha com fundo pulsante
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Text(group.icon)
                        .font(.system(size: 24))
                }

                // Conteúdo central
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Avatares dos participantes
                        StackedAvatarsView(
                            participants: group.participantIDs.map {
                                ParticipantAvatar(userID: $0, name: String($0.prefix(1)), imageData: nil)
                            },
                            size: 24,
                            maxVisible: 4
                        )

                        Text("\(group.currentParticipantCount) \(group.currentParticipantCount == 1 ? "pessoa" : "pessoas")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Tag de tempo restante
                VStack(alignment: .trailing, spacing: 2) {
                    Text(group.isOverTime ? "Tempo extra" : formatTimeInterval(timeRemaining))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(group.isOverTime ? .orange : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(group.isOverTime ? Color.orange.opacity(0.15) : Color.accentColor)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .onAppear { updateTime() }
        .onReceive(timer) { _ in updateTime() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Helpers

    private func updateTime() {
        timeRemaining = max(0, group.expiresAt.timeIntervalSinceNow)
    }

    private var accessibilityDescription: String {
        "Pausinha \(group.title), com \(group.currentParticipantCount) \(group.currentParticipantCount == 1 ? "pessoa" : "pessoas"). Tempo restante: \(formatTimeInterval(timeRemaining))."
    }
}

// MARK: - Preview

#Preview {
    PausinhaCardView(
        group: PausinhaGroup(
            title: "Café",
            icon: "☕️",
            institutionID: "inst1",
            creatorID: "user1",
            participantIDs: ["user1", "user2", "user3"],
            expiresAt: Date().addingTimeInterval(8 * 60)
        ),
        onTap: {}
    )
    .padding()
}
