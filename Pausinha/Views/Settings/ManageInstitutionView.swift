//
//  ManageInstitutionView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import SwiftUI

struct ManageInstitutionView: View {
    @State var institution: Institution
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var institutionService = InstitutionService()
    
    @State private var editedName: String = ""
    @State private var members: [PublicProfile] = []
    @State private var isLoadingMembers = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Informações")) {
                TextField("Nome da Instituição", text: $editedName)
                
                HStack {
                    Text("Código de Convite")
                    Spacer()
                    Text(institution.joinCode)
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section(header: Text("Membros")) {
                if isLoadingMembers {
                    HStack {
                        Spacer()
                        ProgressView("Carregando membros...")
                        Spacer()
                    }
                } else if members.isEmpty {
                    Text("Nenhum membro encontrado.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(members, id: \.userID) { member in
                            if let userID = member.userID {
                                HStack {
                                    Text(member.displayName ?? "Usuário")
                                    Spacer()
                                    
                                    if userID == authService.userID {
                                        Text("Dono")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Button(action: {
                                            Task {
                                                await blockUser(userID)
                                            }
                                        }) {
                                            Text("Bloquear")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if !institution.blockedUserIDs.isEmpty {
                Section(header: Text("Bloqueados")) {
                    List {
                        ForEach(institution.blockedUserIDs, id: \.self) { blockedID in
                            HStack {
                                Text(blockedID)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    Task {
                                        await unblockUser(blockedID)
                                    }
                                }) {
                                    Text("Desbloquear")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Gerenciar Instituição")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") {
                    Task {
                        await saveChanges()
                    }
                }
                .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving || editedName == institution.name)
            }
        }
        .onAppear {
            editedName = institution.name
            Task {
                await loadMembers()
            }
        }
    }
    
    @MainActor
    private func loadMembers() async {
        isLoadingMembers = true
        do {
            members = try await institutionService.fetchMembers(institutionID: institution.id)
            
            // Remove members that are already blocked from the members list visually
            // (In case their public profile still has the institutionID because they haven't opened the app yet to clear it)
            members.removeAll { member in
                if let uid = member.userID {
                    return institution.blockedUserIDs.contains(uid)
                }
                return false
            }
            
        } catch {
            errorMessage = "Falha ao carregar membros: \(error.localizedDescription)"
        }
        isLoadingMembers = false
    }
    
    @MainActor
    private func saveChanges() async {
        isSaving = true
        errorMessage = nil
        let previousName = institution.name
        institution.name = editedName.trimmingCharacters(in: .whitespaces)
        
        do {
            try await institutionService.updateInstitution(institution)
            isSaving = false
        } catch {
            institution.name = previousName
            errorMessage = "Erro ao salvar: \(error.localizedDescription)"
            isSaving = false
        }
    }
    
    @MainActor
    private func blockUser(_ userID: String) async {
        guard !institution.blockedUserIDs.contains(userID) else { return }
        
        errorMessage = nil
        institution.blockedUserIDs.append(userID)
        
        do {
            try await institutionService.updateInstitution(institution)
            // Remove from local members list
            members.removeAll { $0.userID == userID }
        } catch {
            institution.blockedUserIDs.removeAll { $0 == userID }
            errorMessage = "Erro ao bloquear usuário: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func unblockUser(_ userID: String) async {
        guard institution.blockedUserIDs.contains(userID) else { return }
        
        errorMessage = nil
        institution.blockedUserIDs.removeAll { $0 == userID }
        
        do {
            try await institutionService.updateInstitution(institution)
            // Reload members to show them back in the list if they still have the institutionID
            await loadMembers()
        } catch {
            institution.blockedUserIDs.append(userID)
            errorMessage = "Erro ao desbloquear usuário: \(error.localizedDescription)"
        }
    }
}
