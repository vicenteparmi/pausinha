//
//  HomeView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import SwiftUI

struct HomeView: View {
    
    // Navigation
    @State private var isNavigating = false
    @State private var isPresentingProfileView = false
    @State private var isNavigatingCommunity = false
    
    // User authentication state
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header section
                    VStack(spacing: 10) {
                        Image("main_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                        
                        Text("Iniciar pausinha")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                    }.padding(.vertical, 24)
                    
                    // Ongoing title
                    HStack {
                        Text("Em andamento")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    // Community card
                    CommunityCardView(isNavigatingCommunity: $isNavigatingCommunity)
                
                }.padding(.horizontal, 24)
            }
            .toolbar {
                // Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Action for menu button
                    }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
                
                // Profile button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Navigation to ProfileView
                        isNavigating = true
                        isPresentingProfileView = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
            }
            .navigationTitle("Pausinha?")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isNavigating, destination:
                                    {
                if isPresentingProfileView {
                    ProfileView(isLoggedIn: $isLoggedIn)
                }
            }
            )
            .navigationDestination(isPresented: $isNavigatingCommunity) {
                CommunityView()
            }
        }
    }
}

#Preview {
    HomeView()
}
