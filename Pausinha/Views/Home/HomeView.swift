//
//  HomeView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//  Updated by Vicente Parmigiani on 18/05/26 — Fase 2: conectado ao PausinhaService.
//

import SwiftUI

struct HomeView: View {
    enum Destination: Hashable {
        case profile
        case community
        case settings
    }

    @Environment(PausinhaService.self) private var pausinhaService
    @EnvironmentObject var authService: AuthService
    @State private var institutionService = InstitutionService()

    @State private var path: [Destination] = []
    @State private var isPresentingCreateNew = false
    @State private var selectedGroup: PausinhaGroup?
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    private var currentUserID: String {
        UserDefaults.standard.string(forKey: "appleUserID") ?? "unknown"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {

                    // Botão de criar pausinha
                    CreateNewButton(action: {
                        isPresentingCreateNew = true
                    })

                    // MARK: Pausinhas ativas
                    sectionHeader("Em pausinha 🟠", count: pausinhaService.activePausinhas.count)

                    if pausinhaService.isLoading {
                        loadingView
                    } else if pausinhaService.activePausinhas.isEmpty {
                        EmptyPausinhasView()
                    } else {
                        ForEach(pausinhaService.activePausinhas, id: \.id) { group in
                            PausinhaCardView(group: group) {
                                selectedGroup = group
                            }
                        }
                    }

                    // MARK: Histórico (últimas 3 horas)
                    if !pausinhaService.recentClosedPausinhas.isEmpty {
                        sectionHeader("Últimas pausinhas", count: nil)
                            .padding(.top, 8)

                        ForEach(pausinhaService.recentClosedPausinhas, id: \.id) { group in
                            PausinhaCardClosedView(group: group)
                        }
                    }

                    Spacer().frame(height: 32)

                    // Card de comunidade
                    CommunityCardView(onTap: { path.append(.community) })

                }
                .padding(.horizontal, 24)
            }
            .refreshable {
                if let instID = authService.currentUserProfile?.institutionID {
                    await pausinhaService.fetchPausinhas(institutionID: instID)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { path.append(.settings) }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { path.append(.profile) }) {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Pausinha?")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .profile:
                    ProfileView(isLoggedIn: $isLoggedIn)
                case .community:
                    CommunityView()
                case .settings:
                    SettingsView()
                }
            }
            .interactiveDismissDisabled(true)
            .sheet(isPresented: $isPresentingCreateNew) {
                CreateNewPausinhaView()
            }
            .sheet(item: $selectedGroup) { group in
                PausinhaDetailSheet(group: group, currentUserID: currentUserID)
            }
            .task {
                if let instID = authService.currentUserProfile?.institutionID {
                    if instID.hasPrefix("local_") {
                        // Skip CloudKit verification for offline local institutions
                        await pausinhaService.fetchPausinhas(institutionID: instID)
                    } else {
                        // Verifique se o usuário foi bloqueado ou se a instituição foi apagada
                        do {
                            let institution = try await institutionService.fetchInstitution(id: instID)
                            if let userID = authService.userID, institution.blockedUserIDs.contains(userID) {
                                // Usuário foi bloqueado, limpe a instituição
                                authService.updateInstitutionID(nil)
                                return
                            }
                        } catch let error as NSError {
                            if error.code == 404 {
                                // Instituição foi apagada pelo criador
                                authService.updateInstitutionID(nil)
                                return
                            }
                            print("Failed to fetch institution to verify block list: \(error)")
                        }
                        
                        await pausinhaService.fetchPausinhas(institutionID: instID)
                    }
                }
                await pausinhaService.closeExpiredPausinhas()
            }
        }
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String, count: Int?) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .bold()
            if let count = count, count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor))
            }
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Buscando pausinhas...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - PausinhaGroup: Identifiable para .sheet(item:)

extension PausinhaGroup: Identifiable {}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(PausinhaService())
}
