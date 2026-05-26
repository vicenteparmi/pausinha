//
//  AuthService.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import Foundation
import AuthenticationServices
import SwiftData
import CloudKit

class AuthService: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @Published var userID: String?
    @Published var userName: String?
    @Published var currentUserProfile: UserProfile?
    @Published var currentPublicProfile: PublicProfile?
    @Published var isUpdating = false
    @Published var lastError: String?
    @Published var isProfileLoaded = false
    @Published var showReauthAlert = false
    @Published var reauthErrorMessage = ""
    private var completion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?
    private var modelContext: ModelContext?
    private let cloudKitService = CloudKitService()
    
    override init() {
        super.init()
        self.userID = UserDefaults.standard.string(forKey: "appleUserID")
        self.userName = UserDefaults.standard.string(forKey: "appleUserName")
    }
    
    // Set model context for database operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCurrentUserProfile()
        
        // Initialize CloudKit
        Task {
            await cloudKitService.initializeCloudKit()
        }
    }
    
    // Centralized CloudKit error handler for authentication/token failures
    func handleCloudKitError(_ error: Error) {
        let errorString = error.localizedDescription
        var isAuthError = false
        
        if let ckError = error as? CKError {
            if ckError.code == .notAuthenticated {
                isAuthError = true
            }
        }
        
        if errorString.contains("auth token") || 
           errorString.contains("auth_token") || 
           errorString.contains("Account temporarily unavailable") ||
           errorString.contains("bad or missing auth token") ||
           errorString.contains("not authenticated") {
            isAuthError = true
        }
        
        if isAuthError {
            DispatchQueue.main.async {
                self.reauthErrorMessage = "Sua sessão do iCloud expirou ou o token é inválido. Deseja verificar os Ajustes do aparelho ou refazer o login?"
                self.showReauthAlert = true
            }
        }
    }
    
    // Load current user profile from database
    private func loadCurrentUserProfile() {
        print("AuthService: Loading current user profile")
        guard let modelContext = modelContext else { return }
        
        defer {
            self.isProfileLoaded = true
        }

        // If we have a userID (from Sign in with Apple or previously saved), load by it
        if let userID = userID {
            let privateDescriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in profile.userID == userID }
            )

            let publicDescriptor = FetchDescriptor<PublicProfile>(
                predicate: #Predicate { profile in profile.userID == userID }
            )

            do {
                let privateProfiles = try modelContext.fetch(privateDescriptor)
                if let profile = privateProfiles.first {
                    // Existing private profile found
                    self.currentUserProfile = profile
                    self.userName = profile.userName
                    // Load related public profile
                    let publicProfiles = try modelContext.fetch(publicDescriptor)
                    self.currentPublicProfile = publicProfiles.first
                    return
                }
            } catch {
                print("Erro ao carregar perfil do usuário: \(error)")
            }
            // No existing profile found; fall through to create new one
        }

        // If no userID, try to load any existing UserProfile (first one)
        let anyDescriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(anyDescriptor)
            if let profile = profiles.first {
                // adopt this existing profile as the current local user
                self.currentUserProfile = profile
                self.userID = profile.userID
                UserDefaults.standard.set(profile.userID, forKey: "appleUserID")
                self.userName = profile.userName
                UserDefaults.standard.set(self.userName, forKey: "appleUserName")

                // load related public profile if present
                let userID = profile.userID
                let publicDescriptor = FetchDescriptor<PublicProfile>(
                    predicate: #Predicate { p in p.userID == userID && p.userID != nil }
                )
                let publics = try modelContext.fetch(publicDescriptor)
                self.currentPublicProfile = publics.first
                return
            }
        } catch {
            print("Erro ao buscar qualquer perfil existente: \(error)")
        }

        // If no profile exists at all, create a local persistent profile so user data persists
        let generatedID = UUID().uuidString
        let startingName = self.userName ?? UserDefaults.standard.string(forKey: "appleUserName") ?? "Usuário"
        let newProfile = UserProfile(userID: generatedID, userName: startingName)
        modelContext.insert(newProfile)
        self.currentUserProfile = newProfile
        self.userID = generatedID
        UserDefaults.standard.set(generatedID, forKey: "appleUserID")
        UserDefaults.standard.set(startingName, forKey: "appleUserName")

        do {
            try modelContext.save()
        } catch {
            print("Erro ao criar perfil inicial: \(error)")
        }
    }
    
    func signInWithApple(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            self.userID = appleIDCredential.user
            UserDefaults.standard.set(appleIDCredential.user, forKey: "appleUserID")
            let fullName = appleIDCredential.fullName?.givenName ?? appleIDCredential.fullName?.formatted()
            self.userName = fullName
            UserDefaults.standard.set(self.userName, forKey: "appleUserName")
            
            // Create or update user profile in database and complete on MainActor
            Task {
                await createOrUpdateUserProfile(userID: appleIDCredential.user, userName: fullName ?? "Usuário")
                await MainActor.run {
                    self.completion?(.success(appleIDCredential))
                    self.completion = nil
                }
            }
        } else {
            completion?(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Credenciais inválidas"])))
            completion = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func logout() {
        print("AuthService: Logging out user")
        
        // Clear persisted login state
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        // Clean credentials
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        self.userID = nil
        self.userName = nil
        self.currentUserProfile = nil
        self.isProfileLoaded = false
        // Optionally, perform other cleanup
    }
    
    // MARK: - Profile Management
    
    @MainActor
    private func createOrUpdateUserProfile(userID: String, userName: String) async {
        guard let modelContext = modelContext else { return }
        
        let privateDescriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in profile.userID == userID }
        )
        
        let publicDescriptor = FetchDescriptor<PublicProfile>(
            predicate: #Predicate { profile in profile.userID == userID }
        )
        
        // Try to fetch existing user profile from CloudKit first to recover institutionID, profileType, etc.
        var cloudProfileRecord: CKRecord? = nil
        let isICloudAvailable = await cloudKitService.isCloudKitAvailable()
        if isICloudAvailable {
            do {
                let predicate = NSPredicate(format: "userID == %@", userID)
                let records = try await cloudKitService.fetchRecords(ofType: "UserProfile", predicate: predicate, limit: 1)
                cloudProfileRecord = records.first
                if cloudProfileRecord != nil {
                    print("AuthService: Successfully fetched existing user profile from CloudKit")
                }
            } catch {
                print("AuthService: Failed to fetch user profile from CloudKit: \(error.localizedDescription)")
            }
        }
        
        do {
            // Handle private profile
            let privateProfiles = try modelContext.fetch(privateDescriptor)
            
            if let existingProfile = privateProfiles.first {
                // Update existing private profile
                if let cloudRecord = cloudProfileRecord {
                    if let instID = cloudRecord["institutionID"] as? String {
                        existingProfile.institutionID = instID
                    }
                    if let profileType = cloudRecord["profileType"] as? String {
                        existingProfile.profileType = profileType
                    }
                    if let isPublic = cloudRecord["isPublic"] as? Bool {
                        existingProfile.isPublic = isPublic
                    }
                    if let profileImageData = cloudRecord["profileImageData"] as? Data {
                        existingProfile.profileImageData = profileImageData
                    }
                    existingProfile.recordID = cloudRecord.recordID.recordName
                }
                
                existingProfile.userName = userName
                existingProfile.updatedAt = Date()
                self.currentUserProfile = existingProfile
                
                // Save to CloudKit
                do {
                    let record = existingProfile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if existingProfile.recordID != savedRecord.recordID.recordName {
                        existingProfile.recordID = savedRecord.recordID.recordName
                    }
                    print("AuthService: Successfully updated existing profile in CloudKit")
                } catch {
                    print("AuthService: Failed to update existing profile in CloudKit: \(error.localizedDescription)")
                    handleCloudKitError(error)
                }
            } else {
                // Create new private profile
                let newProfile: UserProfile
                if let cloudRecord = cloudProfileRecord {
                    newProfile = UserProfile(from: cloudRecord)
                    // Ensure the userName matches/is updated
                    newProfile.userName = userName
                } else {
                    newProfile = UserProfile(userID: userID, userName: userName)
                }
                
                modelContext.insert(newProfile)
                self.currentUserProfile = newProfile
                
                // Save to CloudKit
                do {
                    let record = newProfile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    newProfile.recordID = savedRecord.recordID.recordName
                    print("AuthService: Successfully created new profile in CloudKit")
                } catch {
                    print("AuthService: Failed to create new profile in CloudKit: \(error.localizedDescription)")
                    handleCloudKitError(error)
                }
            }
            
            // Handle public profile (if user wants to be visible)
            let publicProfiles = try modelContext.fetch(publicDescriptor)
            
            if let existingPublicProfile = publicProfiles.first {
                // Update existing public profile
                existingPublicProfile.displayName = userName
                existingPublicProfile.updateLastSeen()
                self.currentPublicProfile = existingPublicProfile
                
                // Save to CloudKit
                do {
                    let record = existingPublicProfile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if existingPublicProfile.recordID != savedRecord.recordID.recordName {
                        existingPublicProfile.recordID = savedRecord.recordID.recordName
                    }
                    print("AuthService: Successfully updated existing public profile in CloudKit")
                } catch {
                    print("AuthService: Failed to update existing public profile in CloudKit: \(error.localizedDescription)")
                    handleCloudKitError(error)
                }
            } else if currentUserProfile?.isPublic == true {
                // Create new public profile if user wants to be visible
                let newPublicProfile = PublicProfile(
                    userID: userID, 
                    displayName: userName, 
                    profileType: currentUserProfile?.profileType ?? "Bondiano",
                    profileImageData: currentUserProfile?.profileImageData
                )
                modelContext.insert(newPublicProfile)
                self.currentPublicProfile = newPublicProfile
                
                // Save to CloudKit
                do {
                    let record = newPublicProfile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    newPublicProfile.recordID = savedRecord.recordID.recordName
                    print("AuthService: Successfully created new public profile in CloudKit")
                } catch {
                    print("AuthService: Failed to create new public profile in CloudKit: \(error.localizedDescription)")
                    handleCloudKitError(error)
                }
            }
            
            try modelContext.save()
            print("AuthService: Successfully saved profile data locally")
            self.isProfileLoaded = true
        } catch {
            print("Erro ao salvar perfil do usuário: \(error)")
        }
    }
    
    func updateUserName(_ newName: String) {
        print("AuthService: Updating user name to \(newName)")
        guard let modelContext = modelContext, let profile = currentUserProfile else { return }
        
        isUpdating = true
        lastError = nil
        
        profile.updateProfile(name: newName)
        self.userName = newName
        
        // Update public profile if it exists and user is public
        if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
            publicProfile.updatePublicProfile(name: newName)
        }
        
        // Also update UserDefaults for backwards compatibility
        UserDefaults.standard.set(newName, forKey: "appleUserName")
        
        do {
            try modelContext.save()
            // Save to CloudKit asynchronously
            Task { @MainActor in
                do {
                    // Save private profile
                    let record = profile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if profile.recordID != savedRecord.recordID.recordName {
                        profile.recordID = savedRecord.recordID.recordName
                        try modelContext.save()
                    }
                    
                    // Save public profile if exists and user is public
                    if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
                        let publicRecord = publicProfile.getRecord()
                        let savedPublicRecord = try await cloudKitService.saveRecord(publicRecord)
                        
                        // Update recordID if it was newly created
                        if publicProfile.recordID != savedPublicRecord.recordID.recordName {
                            publicProfile.recordID = savedPublicRecord.recordID.recordName
                            try modelContext.save()
                        }
                    }
                    
                    print("AuthService: Successfully synced name update to CloudKit")
                    isUpdating = false
                } catch {
                    print("AuthService: Failed to sync name update to CloudKit: \(error.localizedDescription)")
                    lastError = "Falha ao sincronizar com o iCloud: \(error.localizedDescription)"
                    handleCloudKitError(error)
                    isUpdating = false
                }
            }
        } catch {
            print("Erro ao atualizar nome do usuário: \(error)")
            lastError = "Erro ao salvar localmente: \(error.localizedDescription)"
            isUpdating = false
        }
    }
    
    func updateProfileType(_ newType: String) {
        print("AuthService: Updating profile type to \(newType)")
        guard let modelContext = modelContext, let profile = currentUserProfile else { return }
        
        isUpdating = true
        lastError = nil
        
        profile.updateProfile(type: newType)
        
        // Update public profile if it exists and user is public
        if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
            publicProfile.updatePublicProfile(type: newType)
        }
        
        do {
            try modelContext.save()
            // Save to CloudKit asynchronously
            Task { @MainActor in
                do {
                    // Save private profile
                    let record = profile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if profile.recordID != savedRecord.recordID.recordName {
                        profile.recordID = savedRecord.recordID.recordName
                        try modelContext.save()
                    }
                    
                    // Save public profile if exists and user is public
                    if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
                        let publicRecord = publicProfile.getRecord()
                        let savedPublicRecord = try await cloudKitService.saveRecord(publicRecord)
                        
                        // Update recordID if it was newly created
                        if publicProfile.recordID != savedPublicRecord.recordID.recordName {
                            publicProfile.recordID = savedPublicRecord.recordID.recordName
                            try modelContext.save()
                        }
                    }
                    
                    print("AuthService: Successfully synced profile type update to CloudKit")
                    isUpdating = false
                } catch {
                    print("AuthService: Failed to sync profile type update to CloudKit: \(error.localizedDescription)")
                    lastError = "Falha ao sincronizar tipo de perfil: \(error.localizedDescription)"
                    handleCloudKitError(error)
                    isUpdating = false
                }
            }
        } catch {
            print("Erro ao atualizar tipo de perfil: \(error)")
            lastError = "Erro ao salvar tipo de perfil: \(error.localizedDescription)"
            isUpdating = false
        }
    }
    
    func updateInstitutionID(_ institutionID: String?) {
        print("AuthService: Updating institutionID to \(institutionID ?? "nil")")
        guard let modelContext = modelContext, let profile = currentUserProfile else { return }
        
        // Notify UI immediately before making changes
        self.objectWillChange.send()
        
        isUpdating = true
        lastError = nil
        
        if let id = institutionID {
            profile.updateProfile(institutionID: id)
        } else {
            profile.clearInstitutionID()
        }
        
        // Update public profile if it exists and user is public
        if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
            if let id = institutionID {
                publicProfile.updatePublicProfile(institutionID: id)
            } else {
                publicProfile.clearInstitutionID()
            }
        }
        
        do {
            try modelContext.save()
            // Save to CloudKit asynchronously
            Task { @MainActor in
                do {
                    // Save private profile
                    let record = profile.getRecord()
                    _ = try await cloudKitService.saveRecord(record)
                    
                    // Save public profile if exists
                    if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
                        let publicRecord = publicProfile.getRecord()
                        _ = try await cloudKitService.saveRecord(publicRecord)
                    }
                    
                    print("AuthService: Successfully synced institutionID update to CloudKit")
                    isUpdating = false
                } catch {
                    print("AuthService: Failed to sync institutionID update: \(error.localizedDescription)")
                    lastError = "Falha ao sincronizar instituição: \(error.localizedDescription)"
                    handleCloudKitError(error)
                    isUpdating = false
                }
            }
        } catch {
            print("Erro ao atualizar instituição: \(error)")
            lastError = "Erro ao salvar instituição localmente: \(error.localizedDescription)"
            isUpdating = false
        }
    }
    
    func updateProfileImage(_ imageData: Data) {
        print("AuthService: Updating profile image")
        guard let modelContext = modelContext, let profile = currentUserProfile else { return }
        
        isUpdating = true
        lastError = nil
        
        profile.updateProfile(imageData: imageData)
        
        // Update public profile if it exists and user is public
        if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
            publicProfile.updatePublicProfile(imageData: imageData)
        }
        
        do {
            try modelContext.save()
            // Save to CloudKit asynchronously
            Task { @MainActor in
                do {
                    // Save private profile
                    let record = profile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if profile.recordID != savedRecord.recordID.recordName {
                        profile.recordID = savedRecord.recordID.recordName
                        try modelContext.save()
                    }
                    
                    // Save public profile if exists and user is public
                    if let publicProfile = currentPublicProfile, profile.isPublic ?? false {
                        let publicRecord = publicProfile.getRecord()
                        let savedPublicRecord = try await cloudKitService.saveRecord(publicRecord)
                        
                        // Update recordID if it was newly created
                        if publicProfile.recordID != savedPublicRecord.recordID.recordName {
                            publicProfile.recordID = savedPublicRecord.recordID.recordName
                            try modelContext.save()
                        }
                    }
                    
                    print("AuthService: Successfully synced profile image update to CloudKit")
                    isUpdating = false
                } catch {
                    print("AuthService: Failed to sync profile image update to CloudKit: \(error.localizedDescription)")
                    lastError = "Falha ao sincronizar imagem do perfil: \(error.localizedDescription)"
                    handleCloudKitError(error)
                    isUpdating = false
                }
            }
        } catch {
            print("Erro ao atualizar imagem do perfil: \(error)")
            lastError = "Erro ao salvar imagem do perfil: \(error.localizedDescription)"
            isUpdating = false
        }
    }
    
    func updatePublicVisibility(_ isPublic: Bool) {
        print("AuthService: Updating public visibility to \(isPublic)")
        guard let modelContext = modelContext, let profile = currentUserProfile else { return }
        
        isUpdating = true
        lastError = nil
        
        profile.updateProfile(isPublic: isPublic)
        
        if isPublic && currentPublicProfile == nil {
            // Create public profile if user wants to be visible
            let newPublicProfile = PublicProfile(
                userID: profile.userID ?? "",
                displayName: profile.userName ?? "",
                profileType: profile.profileType ?? "Bondiano",
                profileImageData: profile.profileImageData
            )
            modelContext.insert(newPublicProfile)
            self.currentPublicProfile = newPublicProfile
        } else if !isPublic && currentPublicProfile != nil {
            // Remove public profile if user wants to be private
            if let publicProfile = currentPublicProfile {
                modelContext.delete(publicProfile)
                self.currentPublicProfile = nil
            }
        }
        
        do {
            try modelContext.save()
            // Handle CloudKit sync asynchronously
            Task { @MainActor in
                do {
                    // Always save private profile
                    let record = profile.getRecord()
                    let savedRecord = try await cloudKitService.saveRecord(record)
                    
                    // Update recordID if it was newly created
                    if profile.recordID != savedRecord.recordID.recordName {
                        profile.recordID = savedRecord.recordID.recordName
                        try modelContext.save()
                    }
                    
                    if isPublic {
                        // Save new public profile to CloudKit
                        if let publicProfile = currentPublicProfile {
                            let publicRecord = publicProfile.getRecord()
                            let savedPublicRecord = try await cloudKitService.saveRecord(publicRecord)
                            
                            // Update recordID if it was newly created
                            if publicProfile.recordID != savedPublicRecord.recordID.recordName {
                                publicProfile.recordID = savedPublicRecord.recordID.recordName
                                try modelContext.save()
                            }
                        }
                    } else {
                        // Delete public profile from CloudKit if it exists
                        if let publicProfile = currentPublicProfile,
                           let recordIDString = publicProfile.recordID {
                            let recordID = CKRecord.ID(recordName: recordIDString)
                            try await cloudKitService.deleteRecord(withID: recordID)
                        }
                    }
                    
                    print("AuthService: Successfully synced visibility update to CloudKit")
                    isUpdating = false
                } catch {
                    print("AuthService: Failed to sync visibility update to CloudKit: \(error.localizedDescription)")
                    lastError = "Falha ao sincronizar visibilidade: \(error.localizedDescription)"
                    handleCloudKitError(error)
                    isUpdating = false
                }
            }
        } catch {
            print("Erro ao atualizar visibilidade do perfil: \(error)")
            lastError = "Erro ao salvar visibilidade: \(error.localizedDescription)"
            isUpdating = false
        }
    }
    
    // MARK: - Public Data Management
    
    func fetchAllPublicProfiles() -> [PublicProfile] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<PublicProfile>(
            sortBy: [SortDescriptor(\.lastSeen, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erro ao buscar perfis públicos: \(error)")
            return []
        }
    }
    
    func fetchProfileCategories() -> [ProfileCategory] {
        return ProfileCategory.allCases
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Modern approach for iOS 15+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        // Fallback for older versions
        fatalError("Unable to find presentation anchor")
    }
}