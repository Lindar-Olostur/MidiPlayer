import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(MainContainer.self) private var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAuthSheet = false
    @State private var isSaving = false
    @State private var isLoading = false
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
                        .disabled(isSaving || isLoading)
                        
                        Button {
                            Task {
                                await loadFromCloud()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "icloud.and.arrow.down")
                                }
                                Text("Загрузить из облака")
                            }
                        }
                        .disabled(isSaving || isLoading)
                        
                        if let message = saveMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(message.contains("успешно") || message.contains("загружено") ? .green : .red)
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
    
    private func loadFromCloud() async {
        print("☁️ Начало загрузки из облака...")
        isLoading = true
        saveMessage = nil
        
        do {
            print("📥 Загрузка данных из Firestore...")
            let tunesData: [String: [TuneModel]]? = try await authService.loadFromCloud(collection: "userData", type: [String: [TuneModel]].self)
            
            guard let data = tunesData, let tunes = data["tunes"] else {
                print("⚠️ Данные не найдены в облаке")
                await MainActor.run {
                    saveMessage = "Данные не найдены в облаке"
                    isLoading = false
                }
                return
            }
            
            print("📦 Загружено мелодий: \(tunes.count)")
            for (index, tune) in tunes.enumerated() {
                print("  \(index + 1). \(tune.title) (ID: \(tune.id))")
            }
            
            await MainActor.run {
                for tune in tunes {
                    viewModel.storage.saveTune(tune)
                }
                
                saveMessage = "Загружено \(tunes.count) мелодий из облака"
                isLoading = false
            }
            
            print("✅ Мелодии успешно загружены из облака")
        } catch {
            print("❌ Ошибка загрузки из облака: \(error)")
            print("   Детали: \(error.localizedDescription)")
            await MainActor.run {
                saveMessage = "Ошибка загрузки: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
