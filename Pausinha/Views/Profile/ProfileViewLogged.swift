//
//  ProfileViewLogged.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import SwiftUI
import PhotosUI

struct ProfileViewLogged: View {
    
    @Binding var isLoggedIn: Bool
    @StateObject private var authService = AuthService()
    @Environment(\.modelContext) private var modelContext
    
    // Image picker states
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    // Profile options states
    @State private var selectedType = "Bondiano"
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isPublicProfile = true
    
    // Error handling states
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isUpdating = false
    
    private let typeOptions = ["Bondiano", "Boatardiano", "Mentoria"]
    
    var body: some View {
        VStack {
            // Image selector
            if let image = selectedImage {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        )
                }
                .onChange(of: selectedItem) { _, newItem in
                    guard let newItem = newItem else { return }
                    print("ProfileViewLogged: Image selected, updating profile image")
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                            // Save image to database
                            authService.updateProfileImage(data)
                        }
                    }
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 200, height: 200)
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Carregar Memoji")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    guard let newItem = newItem else { return }
                    print("ProfileViewLogged: Image selected, updating profile image")
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                            // Save image to database
                            authService.updateProfileImage(data)
                        }
                    }
                }
            }
            
            // User name
            Text(authService.userName ?? "Vicente Parmigiani")
                .font(.title)
                .fontWidth(.expanded)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.bottom, 24)
            
            // Options section
            VStack(spacing: 0) {
                // Type picker section
                HStack(spacing: 16) {
                    
                    Text("Tipo de Perfil")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Tipo de Perfil", selection: $selectedType) {
                        ForEach(typeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(authService.isUpdating)
                    .onChange(of: selectedType) { _, newType in
                        print("ProfileViewLogged: Profile type changed to \(newType)")
                        // Save profile type to database
                        authService.updateProfileType(newType)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                
                // Public visibility toggle
                HStack(spacing: 16) {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                    
                    Text("Perfil Público")
                        .foregroundColor(.primary)
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublicProfile)
                        .disabled(authService.isUpdating)
                        .onChange(of: isPublicProfile) { _, newValue in
                            print("ProfileViewLogged: Public visibility changed to \(newValue)")
                            authService.updatePublicVisibility(newValue)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                
                OptionRow(
                    icon: "pencil",
                    iconColor: .orange,
                    title: "Alterar Nome"
                ) {
                    print("ProfileViewLogged: Opening name edit dialog")
                    editedName = authService.userName ?? "Vicente Parmigiani"
                    isEditingName = true
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding(.bottom, 32)
            
            Spacer()
            
            // Sync status indicator
            if authService.isUpdating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sincronizando...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
            }
            
            // Logout button
            Button(action: {
                print("ProfileViewLogged: User logging out")
                // Log out action using AuthService
                authService.logout()
                isLoggedIn = false
            }) {
                Text("Sair")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .foregroundColor(.red)
                    )
            }
            .disabled(authService.isUpdating)
        }
        .padding(.horizontal, 24)
        .onAppear {
            print("ProfileViewLogged: View appeared, loading profile data")
            // Configure AuthService with model context
            authService.setModelContext(modelContext)
            
            // Load profile data
            if let profile = authService.currentUserProfile {
                selectedType = profile.profileType ?? "Bondiano"
                isPublicProfile = profile.isPublic ?? true
                if let imageData = profile.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    selectedImage = Image(uiImage: uiImage)
                }
            }
        }
        .onChange(of: authService.lastError) { _, error in
            if let error = error {
                errorMessage = error
                showErrorAlert = true
                authService.lastError = nil // Reset error after showing
            }
        }
        .alert("Alterar Nome", isPresented: $isEditingName) {
            TextField("Nome", text: $editedName)
            Button("Cancelar", role: .cancel) { }
            Button("Salvar") {
                print("ProfileViewLogged: Saving new name: \(editedName)")
                // Save the name using AuthService
                authService.updateUserName(editedName)
            }
        } message: {
            Text("Digite seu novo nome:")
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Option Row Component
struct OptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color.primary.opacity(isPressed ? 0.1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isPressed)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ProfileViewLogged(
        isLoggedIn: .constant(true),
    )
}
