//
//  CommunityView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import SwiftUI
import SwiftData

struct CommunityView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService()
    @State private var publicProfiles: [PublicProfile] = []
    @State private var categories: [ProfileCategory] = ProfileCategory.allCases
    @State private var selectedCategory: String = "Todos"
    
    var filteredProfiles: [PublicProfile] {
        if selectedCategory == "Todos" {
            return publicProfiles
        } else {
            return publicProfiles.filter { $0.profileType == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header:
                    Picker("Categoria", selection: $selectedCategory) {
                        Text("Todos").tag("Todos")
                        ForEach(categories, id: \.self) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                ) {
                    if filteredProfiles.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Nenhum usuário encontrado")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .fontWeight(.medium)
                            
                            Text("Seja o primeiro a tornar seu perfil público!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredProfiles, id: \.userID) { profile in
                            PublicProfileRow(profile: profile)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitleDisplayMode(.automatic)
            .navigationTitle("Comunidade")
            .onAppear {
                authService.setModelContext(modelContext)
                loadData()
            }
            .refreshable {
                loadData()
            }
        }
    }
    
    private func loadData() {
        publicProfiles = authService.fetchAllPublicProfiles()
    }
}

// MARK: - Public Profile Row Component
struct PublicProfileRow: View {
    let profile: PublicProfile
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: profile.lastSeen ?? Date(), relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            if let imageData = profile.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(profile.profileType ?? "Bondiano")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Circle()
                        .fill((profile.isActive ?? false) ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text((profile.isActive ?? false) ? "Ativo agora" : "Visto \(timeAgo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CommunityView()
        .modelContainer(for: [PublicProfile.self], inMemory: true)
}
