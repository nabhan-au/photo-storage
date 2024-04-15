//
//  SettingView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 13/4/2567 BE.
//

import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

struct SettingView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var imageModel = ImageResultViewModel()
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log out") {
                Task {
                    do {
                        try viewModel.signOut()
                        imageModel.ImageResultList = []
                        showSignInView = true
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
        .navigationBarTitle("Settings")
    }
}

#Preview {
    SettingView(showSignInView: .constant(false))
}
