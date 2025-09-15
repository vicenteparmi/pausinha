//
//  CreateNewButton.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import SwiftUI

struct CreateNewButton: View {
    
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image("main_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                
                Spacer()
                    .frame(height: 8)
                
                Text("Pausinha?")
                    .fontWeight(.semibold)
                    .fontWidth(.expanded)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
            }
            .padding(32)
            .background(
                Rectangle()
                    .fill(Color.white)
                    .clipShape(.buttonBorder)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    CreateNewButton(action: {})
        .padding()
}
