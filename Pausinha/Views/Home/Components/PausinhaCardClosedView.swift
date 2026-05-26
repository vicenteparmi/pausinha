//
//  PausinhaCardClosedView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//
//  Card de pausinha ENCERRADA exibido na seção "Últimas Pausinhas".
//  Visual em escala de cinza com opacidade reduzida (60%), conforme o DESIGN.md.
//

import SwiftUI

struct PausinhaCardClosedView: View {
    let group: PausinhaGroup

    var body: some View {
        HStack(spacing: 16) {

            // Ícone da pausinha encerrada
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(group.icon)
                    .font(.system(size: 20))
                    .grayscale(1.0)
            }

            // Conteúdo central
            VStack(alignment: .leading, spacing: 6) {
                Text(group.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StackedAvatarsView(
                        participants: group.participantIDs.map {
                            ParticipantAvatar(userID: $0, name: String($0.prefix(1)), imageData: nil)
                        },
                        size: 22,
                        maxVisible: 4,
                        borderColor: Color(UIColor.systemBackground)
                    )

                    Text("\(group.currentParticipantCount) \(group.currentParticipantCount == 1 ? "pessoa" : "pessoas")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Horário em que foi encerrado
            VStack(alignment: .trailing, spacing: 2) {
                Text("Encerrada")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(relativeTime)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        // Escala de cinza + opacidade reduzida conforme DESIGN.md
        .grayscale(1.0)
        .opacity(0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pausinha encerrada: \(group.title), com \(group.currentParticipantCount) \(group.currentParticipantCount == 1 ? "pessoa" : "pessoas"). Encerrada \(relativeTime).")
    }

    // MARK: - Helpers

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: group.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    PausinhaCardClosedView(
        group: PausinhaGroup(
            title: "Almoço",
            icon: "🍕",
            institutionID: "inst1",
            creatorID: "user1",
            participantIDs: ["user1", "user2"],
            expiresAt: Date().addingTimeInterval(-30 * 60)
        )
    )
    .padding()
}
