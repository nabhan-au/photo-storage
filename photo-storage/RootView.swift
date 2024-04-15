//
//  RootView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 13/4/2567 BE.
//

import SwiftUI
import SimpleToast

struct RootView: View {
    
    @State private var showSignInView: Bool = false
    @State var showToast: ToastObject? = nil
    @StateObject private var imageViewModel = ImageResultViewModel()
    
    private let toastOptions = SimpleToastOptions(
        hideAfter: 5
    )
    
    var body: some View {
        VStack {
            TabView {
                MainView(imageView: imageViewModel, showToast: $showToast)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                SettingView(showSignInView: $showSignInView)
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
                FavoriteView(imageView: imageViewModel, showToast: $showToast)
                    .tabItem {
                        Label("Favorite", systemImage: "heart.fill")
                    }
            }
//            Button("Show toast") {
//                        withAnimation {
//                            // Toggle the item
//                            showToast = showToast == nil ? DummyItem() : nil
//                        }
//                    }
        }
        .simpleToast(item: $showToast, options: toastOptions) {
                HStack {
                    Image(systemName: showToast?.symbol ?? "")
                    Text(showToast?.message ?? "")
                }
                .padding()
                .background(showToast?.color ?? Color.white)
                .foregroundColor(Color.white)
                .cornerRadius(10)
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
