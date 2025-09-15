//
//  HomeView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import SwiftUI

struct HomeView: View {
    enum Destination: Hashable {
        case profile
        case community
        case settings
    }
    
    // Navigation path
    @State private var path: [Destination] = []
    // CreateNew sheet state
    @State private var isPresentingCreateNew = false
    // User authentication state
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header section
                    CreateNewButton(action: {
                        isPresentingCreateNew = true
                    })
                    
                    // Ongoing title
                    HStack {
                        Text("Em andamento")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    // Empty state view
                    EmptyPausinhasView()
                    
                    // Upcoming title
                    HStack {
                        Text("Próximas")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    // Empty state view
                    EmptyPausinhasView()
                    
                    // Completed title
                    HStack {
                        Text("Concluídas")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    // Empty state view
                    EmptyPausinhasView()
                    
                    Spacer().frame(height: 32)
                    
                    // Community card
                    CommunityCardView(onTap: { path.append(.community) })
                
                }.padding(.horizontal, 24)
            }
            .toolbar {
                // Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        path.append(.settings)
                    }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
                
                // Profile button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { path.append(.profile) }) {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                            .foregroundColor(.black)
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
            
        }
    }
}

#Preview {
    HomeView()
}
