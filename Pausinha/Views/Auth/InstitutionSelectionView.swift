//
//  InstitutionSelectionView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import SwiftUI
import SwiftData

struct InstitutionSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var authService: AuthService
    @Binding var isLoggedIn: Bool
    
    @State private var institutionService = InstitutionService()
    
    @State private var isCreating = false
    @State private var isJoining = false
    @State private var inputName = ""
    @State private var inputCode = ""
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var myInstitutions: [Institution] = []
    @State private var isFetchingInstitutions = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Text("Instituição")
                    .font(.largeTitle)
                    .bold()
                
                Text("Crie uma nova organização ou junte-se a uma existente usando um código.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                if institutionService.isLoading {
                    ProgressView("Processando...")
                } else {
                    VStack(spacing: 16) {
                        Button(action: {
                            isCreating = true
                        }) {
                            Text("Criar Nova Instituição")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().foregroundColor(.accentColor))
                        }
                        
                        Button(action: {
                            isJoining = true
                        }) {
                            Text("Entrar com Código")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().stroke(Color.accentColor, lineWidth: 2))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if !isFetchingInstitutions && !myInstitutions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Minhas Instituições")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(myInstitutions, id: \.id) { inst in
                                        Button(action: {
                                            authService.updateInstitutionID(inst.id)
                                        }) {
                                            HStack {
                                                Text(inst.name)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(12)
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .task {
                await checkiCloudAvailability(showAlert: true)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await checkiCloudAvailability(showAlert: false)
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                createSheet
            }
            .sheet(isPresented: $isJoining) {
                joinSheet
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Erro"),
                    message: Text(errorMessage ?? "Ocorreu um erro desconhecido."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var createSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Nome da Instituição")) {
                    TextField("Ex: Apple Developer Academy", text: $inputName)
                }
            }
            .navigationTitle("Nova Instituição")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isCreating = false
                        inputName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        Task {
                            await createInstitution()
                        }
                    }
                    .disabled(inputName.isEmpty)
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Erro"),
                    message: Text(errorMessage ?? "Ocorreu um erro desconhecido."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var joinSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Código de Convite")) {
                    TextField("Ex: AB12CD", text: $inputCode)
                        .textInputAutocapitalization(.characters)
                }
            }
            .navigationTitle("Entrar na Instituição")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isJoining = false
                        inputCode = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Entrar") {
                        Task {
                            await joinInstitution()
                        }
                    }
                    .disabled(inputCode.count < 6)
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Erro"),
                    message: Text(errorMessage ?? "Ocorreu um erro desconhecido."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    @MainActor
    private func createInstitution() async {
        guard let userID = authService.userID else { return }
        do {
            let institution = try await institutionService.createInstitution(name: inputName, creatorID: userID)
            authService.updateInstitutionID(institution.id)
            isCreating = false
        } catch {
            print("Create Institution Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showErrorAlert = true
            authService.handleCloudKitError(error)
        }
    }
    
    @MainActor
    private func joinInstitution() async {
        do {
            let cleanCode = inputCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let institution = try await institutionService.joinInstitution(code: cleanCode)
            authService.updateInstitutionID(institution.id)
            isJoining = false
        } catch {
            print("Join Institution Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showErrorAlert = true
            authService.handleCloudKitError(error)
        }
    }
    
    @MainActor
    private func checkiCloudAvailability(showAlert: Bool) async {
        let isDev = authService.userID == "dev_user"
        
        if isDev {
            await loadMyInstitutions()
            return
        }
        
        let isAvailable = await institutionService.isAccountAvailable()
        if !isAvailable {
            if showAlert {
                errorMessage = "Conta iCloud não disponível. Por favor, faça login no iCloud nas configurações do seu aparelho para continuar."
                showErrorAlert = true
            }
        } else {
            await loadMyInstitutions()
        }
    }

    @MainActor
    private func loadMyInstitutions() async {
        guard let userID = authService.userID else {
            isFetchingInstitutions = false
            return
        }
        do {
            isFetchingInstitutions = true
            myInstitutions = try await institutionService.fetchMyInstitutions(userID: userID)
            isFetchingInstitutions = false
        } catch {
            print("Failed to fetch my institutions: \(error)")
            isFetchingInstitutions = false
        }
    }
}

// MARK: - Previews
#Preview {
    InstitutionSelectionView(authService: AuthService(), isLoggedIn: .constant(true))
}
