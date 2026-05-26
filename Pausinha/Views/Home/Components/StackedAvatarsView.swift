//
//  StackedAvatarsView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//
//  Exibe avatares empilhados (sobrepostos) dos participantes de uma pausinha.
//  Se não houver imagem, exibe a inicial do nome sobre um círculo colorido.
//

import SwiftUI

// MARK: - Avatar Model

struct ParticipantAvatar {
    let userID: String
    let name: String
    let imageData: Data?

    /// Cor derivada deterministicamente do userID para consistência entre sessões.
    var fallbackColor: Color {
        let palette: [Color] = [
            Color(hex: "#FFB347"), // laranja pastel
            Color(hex: "#AEC6CF"), // azul bebê
            Color(hex: "#B5EAD7"), // verde menta
            Color(hex: "#FFDAC1"), // pêssego
            Color(hex: "#C7CEEA"), // lilás
            Color(hex: "#FF9AA2"), // rosa
            Color(hex: "#E2F0CB"), // verde claro
        ]
        let index = abs(userID.hashValue) % palette.count
        return palette[index]
    }

    var initial: String {
        String(name.prefix(1)).uppercased()
    }
}

// MARK: - StackedAvatarsView

struct StackedAvatarsView: View {
    let participants: [ParticipantAvatar]
    var size: CGFloat = 36
    var maxVisible: Int = 4
    var borderColor: Color = .white

    private var visible: [ParticipantAvatar] {
        Array(participants.prefix(maxVisible))
    }

    private var overflow: Int {
        max(0, participants.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.offset) { index, avatar in
                avatarCircle(for: avatar)
                    .offset(x: CGFloat(index) * -(size * 0.35))
                    .zIndex(Double(visible.count - index))
            }

            if overflow > 0 {
                overflowBubble
                    .offset(x: CGFloat(visible.count) * -(size * 0.35))
            }
        }
        .padding(.trailing, CGFloat(max(0, visible.count - 1)) * -(size * 0.35))
    }

    @ViewBuilder
    private func avatarCircle(for avatar: ParticipantAvatar) -> some View {
        Group {
            if let data = avatar.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                avatar.fallbackColor
                    .overlay(
                        Text(avatar.initial)
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: 2.5)
        )
        .accessibilityLabel("Avatar de \(avatar.name)")
    }

    private var overflowBubble: some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemGray5))
                .overlay(Circle().stroke(borderColor, lineWidth: 2.5))

            Text("+\(overflow)")
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(overflow) participantes adicionais")
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        StackedAvatarsView(participants: [
            ParticipantAvatar(userID: "1", name: "Ana", imageData: nil),
            ParticipantAvatar(userID: "2", name: "Bruno", imageData: nil),
            ParticipantAvatar(userID: "3", name: "Carol", imageData: nil),
        ], size: 40)

        StackedAvatarsView(participants: [
            ParticipantAvatar(userID: "1", name: "Ana", imageData: nil),
            ParticipantAvatar(userID: "2", name: "Bruno", imageData: nil),
            ParticipantAvatar(userID: "3", name: "Carol", imageData: nil),
            ParticipantAvatar(userID: "4", name: "Diego", imageData: nil),
            ParticipantAvatar(userID: "5", name: "Eva", imageData: nil),
            ParticipantAvatar(userID: "6", name: "Felipe", imageData: nil),
        ], size: 40)
    }
    .padding()
}
