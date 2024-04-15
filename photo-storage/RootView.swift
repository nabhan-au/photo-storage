//
//  RootView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 13/4/2567 BE.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSignInView: Bool = false
    @StateObject private var imageViewModel = ImageResultViewModel()
    
    var body: some View {
        ZStack {
            TabView {
                MainView(imageView: imageViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                SettingView(showSignInView: $showSignInView)
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
                FavoriteView(imageView: imageViewModel)
                    .tabItem {
                        Label("Favorite", systemImage: "heart.fill")
                    }
            }
        }
        .onAppear {
            let user = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = user == nil ? true : false
        }
        .fullScreenCover(isPresented: $showSignInView, content: {
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        })
        
    }
}

#Preview {
    RootView()
}
