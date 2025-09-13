//
//  ProfileViewEmpty.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import SwiftUI

public struct ProfileViewEmpty: View {
    @StateObject private var authService = AuthService()
    @State private var authMessage: String?
    
    @Binding var isLoggedIn: Bool
    
    public var body: some View {
        VStack {
            // Memoji image
            Image("memoji")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            
            // Prompt text
            Text("Bora entrar pra fazer pausinhas?")
                .fontWidth(.expanded)
                .multilineTextAlignment(.center)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Spacer().frame(height: 32)
            
            // Button to navigate to login
            Button(action: {
                authService.signInWithApple { result in
                    switch result {
                    case .success(let credential):
                        authMessage = "Login bem-sucedido! Usuário: \(credential.user)"
                        isLoggedIn = true
                        // Persistir o estado de login
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        // Aqui você pode salvar os dados do usuário se necessário
                    case .failure(let error):
                        authMessage = "Erro no login: \(error.localizedDescription)"
                    }
                }
            }) {
                Text("Entrar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .foregroundColor(.accentColor)
                    )
            }
            
            if let message = authMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding(.top, 16)
            }
            
        }
    }
}

#Preview {
    ProfileViewEmpty(isLoggedIn: .constant(false))
}
