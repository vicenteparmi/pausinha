//
//  SettingsView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthService
    @State private var institutionService = InstitutionService()
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    
    @State private var showingLeaveAlert = false
    @State private var currentInstitution: Institution?
    @State private var isLoadingInstitution = false
    
    var isOwner: Bool {
        guard let inst = currentInstitution, let userID = authService.userID else { return false }
        return inst.creatorID == userID
    }
    
    var body: some View {
        Form {
            Section(header: Text("Perfil")) {
                HStack {
                    Text("Nome")
                    Spacer()
                    Text(authService.userName ?? "Desconhecido")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Instituição")) {
                if let instID = authService.currentUserProfile?.institutionID {
                    HStack {
                        Text("ID da Instituição")
                        Spacer()
                        Text(instID)
                            .foregroundColor(.secondary)
                    }
                    
                    if isLoadingInstitution {
                        HStack {
                            Text("Nome")
                            Spacer()
                            ProgressView()
                        }
                    } else if let inst = currentInstitution {
                        HStack {
                            Text("Nome")
                            Spacer()
                            Text(inst.name)
                                .foregroundColor(.secondary)
                        }
                        
                        if isOwner {
                            NavigationLink {
                                ManageInstitutionView(institution: inst)
                            } label: {
                                Text("Gerenciar Instituição")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showingLeaveAlert = true
                    }) {
                        Text(isOwner ? "Excluir Instituição" : "Sair da Instituição")
                    }
                } else {
                    Text("Nenhuma instituição vinculada.")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    authService.logout()
                    isLoggedIn = false
                }) {
                    Text("Fazer Logout")
                }
            }
        }
        .navigationTitle("Configurações")
        .alert(isOwner ? "Excluir Instituição" : "Sair da Instituição", isPresented: $showingLeaveAlert) {
            Button("Cancelar", role: .cancel) { }
            Button(isOwner ? "Excluir" : "Sair", role: .destructive) {
                if isOwner {
                    Task {
                        await deleteInstitution()
                    }
                } else {
                    leaveInstitution()
                }
            }
        } message: {
            if isOwner {
                Text("Como criador, você não pode simplesmente sair. Deseja excluir esta instituição permanentemente? Todos os membros perderão o acesso.")
            } else {
                Text("Tem certeza que deseja sair desta instituição? Você precisará de um código de convite para entrar novamente.")
            }
        }
        .task {
            if let instID = authService.currentUserProfile?.institutionID {
                isLoadingInstitution = true
                do {
                    currentInstitution = try await institutionService.fetchInstitution(id: instID)
                } catch {
                    print("SettingsView: falha ao carregar instituição: \(error)")
                }
                isLoadingInstitution = false
            }
        }
    }
    
    private func leaveInstitution() {
        authService.updateInstitutionID(nil)
    }
    
    @MainActor
    private func deleteInstitution() async {
        if let inst = currentInstitution {
            do {
                try await institutionService.deleteInstitution(inst)
                authService.updateInstitutionID(nil)
            } catch let error as NSError {
                print("SettingsView: falha ao excluir instituição: \(error)")
                // Força a saída mesmo se der erro (ex: já foi apagada ou problema de rede) para não prender o dono
                authService.updateInstitutionID(nil)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}
