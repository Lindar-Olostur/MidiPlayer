import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(MainContainer.self) private var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAuthSheet = false
    @State private var isSaving = false
    @State private var saveMessage: String?
    
    var body: some View {
        NavigationStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
            }

            List {
                Section("Облачное хранилище") {
                    if authService.isAuthenticated {
                        HStack {
                            Text("Вошел как")
                            Spacer()
                            Text(authService.currentUser?.email ?? "")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            Task {
                                await saveToCloud()
                            }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "icloud.and.arrow.up")
                                }
                                Text("Сохранить на облако")
                            }
                        }
                        .disabled(isSaving)
                        
                        if let message = saveMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(message.contains("успешно") ? .green : .red)
                        }
                        
                        Button("Выйти", role: .destructive) {
                            try? authService.signOut()
                        }
                    } else {
                        Button("Войти") {
                            showingAuthSheet = true
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .sheet(isPresented: $showingAuthSheet) {
                AuthView()
                    .environment(authService)
            }
        }
    }
    
    private func saveToCloud() async {
        print("☁️ Начало сохранения на облако...")
        isSaving = true
        saveMessage = nil
        
        do {
            let tunes = viewModel.storage.fetchAllTunes()
            print("📦 Найдено мелодий для сохранения: \(tunes.count)")
            
            for (index, tune) in tunes.enumerated() {
                print("  \(index + 1). \(tune.title) (ID: \(tune.id))")
            }
            
            let tunesData: [String: [TuneModel]] = ["tunes": tunes]
            print("💾 Отправка данных в Firestore...")
            try await authService.saveToCloud(data: tunesData, collection: "userData")
            
            print("✅ Мелодии успешно сохранены на облако")
            await MainActor.run {
                saveMessage = "Мелодии успешно сохранены на облако"
                isSaving = false
            }
        } catch {
            print("❌ Ошибка сохранения на облако: \(error)")
            print("   Детали: \(error.localizedDescription)")
            await MainActor.run {
                saveMessage = "Ошибка сохранения: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}
