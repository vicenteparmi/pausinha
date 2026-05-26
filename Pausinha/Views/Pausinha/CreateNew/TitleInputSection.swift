//
//  TitleInputSection.swift
//  Pausinha
//
//  Campo de título + chips de sugestão do formulário de criação.
//

import SwiftUI

struct TitleInputSection: View {
    @Binding var title: String

    private let suggestions = ["Café ☕", "Almoço 🍕", "Uno 🃏", "Churrasco 🔥", "Futebol ⚽"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("O que vamos fazer?", systemImage: "text.cursor")
                .font(.headline)

            TextField("Ex: Café na copa...", text: $title)
                .font(.body).padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .submitLabel(.done)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { s in
                        Button {
                            title = s
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(s).font(.subheadline)
                                .foregroundColor(title == s ? .white : .primary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(
                                    Capsule().fill(title == s ? Color.accentColor : Color(UIColor.systemGray5))
                                )
                        }
                        .animation(.easeInOut(duration: 0.15), value: title)
                    }
                }
            }
        }
    }
}
