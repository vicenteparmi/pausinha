//
//  AuthService.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import Foundation
import AuthenticationServices

class AuthService: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @Published var userID: String?
    @Published var userName: String?
    private var completion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?
    
    override init() {
        super.init()
        self.userID = UserDefaults.standard.string(forKey: "appleUserID")
        self.userName = UserDefaults.standard.string(forKey: "appleUserName")
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
            self.userName = appleIDCredential.fullName?.givenName ?? appleIDCredential.fullName?.formatted()
            UserDefaults.standard.set(self.userName, forKey: "appleUserName")
            completion?(.success(appleIDCredential))
        } else {
            completion?(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Credenciais inválidas"])))
        }
        completion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func logout() {
        // Clear persisted login state
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        // Clean credentials
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        self.userID = nil
        self.userName = nil
        // Optionally, perform other cleanup
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}