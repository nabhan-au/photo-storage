//
//  RegisterView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 11/5/2567 BE.
//

import SwiftUI
import SimpleToast

@MainActor
final class RegisterViewModel: ObservableObject {
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

struct RegisterView: View {
    
    @StateObject private var viewModel = RegisterViewModel()
    @State var showToast: ToastObject? = nil
    @Binding var showSignInView: Bool
    @Binding var showRegisterView: Bool
    @Binding var mainPageshowToast: ToastObject?
    private let toastOptions = SimpleToastOptions(
        hideAfter: 5
    )
    
    var body: some View {
        VStack {
            TextField("Email", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)
            Button {
                Task {
                    do {
                        try await viewModel.signUp()
                        showSignInView = false
                        showRegisterView = false
                        mainPageshowToast = ToastObject(message: "Register success", symbol: "square.and.arrow.down.on.square", color: Color.green.opacity(0.9))
                        return
                    } catch {
                        showToast = ToastObject(message: "Register failed", symbol: "square.and.arrow.down.on.square", color: Color.red.opacity(0.9))
                        print("Error: \(error)")
                    }
                    do {
                        let user = try? AuthenticationManager.shared.getAuthenticatedUser()
                    }
                }
                
            } label: {
                Text("Register")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Button {
                Task {
                    showRegisterView = false
                }
                
            } label: {
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Register with email")
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
