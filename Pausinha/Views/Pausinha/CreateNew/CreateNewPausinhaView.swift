//
//  CreateNewPausinhaView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import SwiftUI

struct CreateNewPausinhaView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
            }
            .navigationTitle("Criar pausinha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Cancel button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Voltar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Create button
                    Button(action: {
                        // Action to create a new pausinha
                    }) {
                        Text("Criar")
                            .bold()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateNewPausinhaView()
}
