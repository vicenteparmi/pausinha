//
//  AuthView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import SwiftUI

struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthService
    
    @State private var authMessage: String?
    
    var body: some View {
        VStack {
            Spacer()
            
            // Note: Make sure "memoji" image exists in Assets
            Image("memoji")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            
            Text("Bem-vindo ao Pausinha")
                .font(.largeTitle)
                .bold()
                .padding(.top, 16)
            
            Text("Conecte-se com sua equipe e faça pausas juntos.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            
            Spacer()
            
            Button(action: {
                authService.signInWithApple { result in
                    switch result {
                    case .success(_):
                        authMessage = "Login bem-sucedido!"
                        isLoggedIn = true
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    case .failure(let error):
                        authMessage = "Erro no login: \(error.localizedDescription)"
                    }
                }
            }) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Entrar com a Apple")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().foregroundColor(.black))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            // For testing bypass
            Button("Bypass Login (Dev)") {
                UserDefaults.standard.set("dev_user", forKey: "appleUserID")
                UserDefaults.standard.set("Dev User", forKey: "appleUserName")
                authService.userID = "dev_user"
                authService.userName = "Dev User"
                isLoggedIn = true
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                
                // Force load profile
                authService.setModelContext(modelContext)
            }
            .padding(.bottom, 16)
            
            if let message = authMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            authService.setModelContext(modelContext)
        }
    }
}

#Preview {
    AuthView(isLoggedIn: .constant(false))
        .environmentObject(AuthService())
}
