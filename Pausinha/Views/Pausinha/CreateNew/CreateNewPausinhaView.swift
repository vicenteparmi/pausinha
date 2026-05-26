//
//  CreateNewPausinhaView.swift
//  Pausinha
//
//  Updated on 18/05/26 — duração livre + horário fixo de encerramento.
//

import SwiftUI

struct CreateNewPausinhaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PausinhaService.self) private var pausinhaService
    @EnvironmentObject var authService: AuthService

    let availableEmojis = ["☕️", "🎮", "🍔", "🧘‍♀️", "🚶‍♂️", "💬", "🎧", "📖", "🍺", "🍦"]
    @State private var selectedIcon: String = "☕️"
    
    @State private var title: String = ""
    @State private var timeMode: TimeMode = .duration
    @State private var selectedPresetMinutes: Int? = 15
    @State private var customMinutes: Int = 15
    @State private var endTime: Date = Self.defaultEndTime()
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var currentUserID: String {
        UserDefaults.standard.string(forKey: "appleUserID") ?? "unknown"
    }

    private var expiresAt: Date {
        switch timeMode {
        case .duration:
            return Date().addingTimeInterval(TimeInterval(effectiveMinutes * 60))
        case .endTime:
            if endTime <= Date() {
                return Calendar.current.date(byAdding: .day, value: 1, to: endTime) ?? endTime
            }
            return endTime
        }
    }

    private var effectiveMinutes: Int { selectedPresetMinutes ?? customMinutes }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isCreating && expiresAt > Date()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // Emoji Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedIcon = emoji
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    TitleInputSection(title: $title)

                    DurationInputSection(
                        timeMode: $timeMode,
                        selectedPresetMinutes: $selectedPresetMinutes,
                        customMinutes: $customMinutes,
                        endTime: $endTime,
                        effectiveMinutes: effectiveMinutes,
                        expiresAt: expiresAt
                    )

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption).foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("Criar pausinha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.secondary)
                            .padding(8).background(Circle().fill(Color(UIColor.systemGray5)))
                    }
                    .accessibilityLabel("Cancelar")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await createPausinha() } } label: {
                        if isCreating { ProgressView().scaleEffect(0.85) }
                        else { Text("Criar").fontWeight(.semibold) }
                    }
                    .disabled(!canCreate)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                selectedIcon = availableEmojis.randomElement() ?? "☕️"
            }
        }
    }

    // MARK: - Action

    @MainActor
    private func createPausinha() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        
        guard let instID = authService.currentUserProfile?.institutionID else {
            errorMessage = "Você precisa estar em uma instituição para criar uma pausinha."
            return
        }
        
        isCreating = true
        errorMessage = nil
        do {
            _ = try await pausinhaService.createPausinha(
                title: trimmedTitle,
                icon: selectedIcon,
                institutionID: instID,
                creatorID: currentUserID,
                expiresAt: expiresAt
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            authService.handleCloudKitError(error)
        }
        isCreating = false
    }

    // MARK: - Helpers

    static func defaultEndTime() -> Date {
        var c = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: Date())
        if (c.minute ?? 0) < 30 { c.minute = 30 }
        else { c.minute = 0; c.hour = (c.hour ?? 0) + 1 }
        return Calendar.current.date(from: c) ?? Date().addingTimeInterval(1800)
    }
}

#Preview {
    CreateNewPausinhaView().environment(PausinhaService())
}
