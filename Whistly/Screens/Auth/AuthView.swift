import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingResetPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Пароль", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(isSignUp ? "Зарегистрироваться" : "Войти") {
                        Task {
                            await authenticate()
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    if !isSignUp {
                        Button("Забыли пароль?") {
                            showingResetPassword = true
                        }
                    }
                }
                
                Section {
                    Button(isSignUp ? "Уже есть аккаунт?" : "Создать аккаунт") {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                }
            }
            .navigationTitle(isSignUp ? "Регистрация" : "Вход")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
            .alert("Сброс пароля", isPresented: $showingResetPassword) {
                TextField("Email", text: $email)
                Button("Отправить") {
                    Task {
                        await resetPassword()
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Введите ваш email для сброса пароля")
            }
        }
    }
    
    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func resetPassword() async {
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "Письмо для сброса пароля отправлено"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
