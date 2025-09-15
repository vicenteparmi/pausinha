//
//  CommunityCardView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import SwiftUI

public struct CommunityCardView: View {
    public var onTap: () -> Void

    public var body: some View {
        // Community section
        VStack(alignment: .leading, spacing: 12) {
            VStack (alignment: .leading, spacing: 4) {
                Text("Academers")
                    .font(.title2)
                    .bold()
                Text("Encontre todos os academers que aderiram a pausinha.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(12)
            
            Button(action: onTap) {
                Text("Ver todos")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .foregroundColor(.accentColor)
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.accent.opacity(0.1))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )

    }
}

#Preview {
    CommunityCardView(onTap: {})
        .padding()
}
