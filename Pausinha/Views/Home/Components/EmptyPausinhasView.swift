//
//  EmptyPausinhasView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import SwiftUI

struct EmptyPausinhasView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "macwindow.and.cursorarrow")
                .font(.system(size: 48))
                .foregroundStyle(.accent)
            
            VStack(spacing: 4) {
                Text("Nada por aqui...")
                    .font(.title2)
                    .bold()
                
                Text("Nenhuma pausinha por aqui hoje")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    EmptyPausinhasView()
        .padding()
}
