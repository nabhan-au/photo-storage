//
//  SignInEmailView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 13/4/2567 BE.
//

import SwiftUI
import SimpleToast

@MainActor
final class SignInEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        try await AuthenticationManager.shared.createUser(email: email, password: password)
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        try await AuthenticationManager.shared.signIn(email: email, password: password)
    }
}

struct SignInEmailView: View {
    
    @StateObject private var viewModel = SignInEmailViewModel()
    @State var showToast: ToastObject? = nil
    @Binding var showSignInView: Bool
    @Binding var showRegisterView: Bool
    private let toastOptions = SimpleToastOptions(
        hideAfter: 5
    )
    
    
    var body: some View {
        ZStack {
                Color(UIColor.systemBackground) // Base background for adaptability in light/dark mode
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) { // Adjusted overall spacing for a more airy layout
                    Spacer()
                    
                    // Logo or Picture icon with label, centered
                    VStack {
                        Image(systemName: "photo.on.rectangle") // Using an iconic Airbnb-like symbol
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color.pink) // Airbnb's brand color

                        Text("Pic Storage")
                            .font(.largeTitle) // More prominent title in the style of Airbnb
                            .fontWeight(.bold)
                            .foregroundColor(Color.pink)
                    }
                    .padding()
                    .background(Color.clear)

                    // Email input
                    TextField("Enter your email", text: $viewModel.email)
                        .padding()
                        .background(Color.secondary.opacity(0.1)) // Subtly styled input field
                        .cornerRadius(20)
                        .shadow(radius: 10, y: 5)

                    // Password input
                    SecureField("Enter your password", text: $viewModel.password)
                        .padding()
                        .background(Color.secondary.opacity(0.1)) // Consistency in input styling
                        .cornerRadius(20)
                        .shadow(radius: 10, y: 5)

                    // Sign In button
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.signIn()
                                showSignInView = false
                            } catch {
                                showToast = ToastObject(message: "Login failed, email or password is not correct", symbol: "exclamationmark.triangle", color: Color.red.opacity(0.8))
                                print("Error: \(error)")
                            }
                        }
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.pink]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }

                    // Register button
                    Button(action: {
                        Task {
                            showRegisterView = true
                        }
                    }) {
                        Text("Register")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 20, trailing: 30)) // Increased padding for better focus
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
    }
}

//#Preview {
//    NavigationStack{
//        SignInEmailView(showSignInView: .constant(false), showRegisterView: .constant(false))
//    }
//}
