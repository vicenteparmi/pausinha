//
//  ContentView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 12/09/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthService
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        Group {
            if !isLoggedIn {
                AuthView(isLoggedIn: $isLoggedIn)
            } else if !authService.isProfileLoaded {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Carregando perfil...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            } else if authService.currentUserProfile?.institutionID == nil {
                InstitutionSelectionView(authService: authService, isLoggedIn: $isLoggedIn)
            } else {
                HomeView()
            }
        }
        .onAppear {
            authService.setModelContext(modelContext)
        }
        .alert("Conexão com o iCloud", isPresented: $authService.showReauthAlert) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            Button("Refazer Login (Sair)", role: .destructive) {
                authService.logout()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(authService.reauthErrorMessage)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, UserProfile.self, PublicProfile.self, Institution.self], inMemory: true)
        .environmentObject(AuthService())
}
