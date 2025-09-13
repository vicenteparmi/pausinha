//
//  ProfileView.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import SwiftUI

struct ProfileView: View {
    
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        if isLoggedIn {
            ProfileViewLogged(isLoggedIn: $isLoggedIn)
        } else {
            ProfileViewEmpty(isLoggedIn: $isLoggedIn)
        }
    }
}
