//
//  FileImportView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void
        
        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Для iOS нужно получить доступ к файлу
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security scoped resource")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            onDocumentPicked(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Пользователь отменил выбор
        }
    }
}

// MARK: - File Import View

struct FileImportView: View {
    @ObservedObject var tuneManager: TuneManager
    @Environment(\.dismiss) var dismiss
    @State private var showPicker = false
    @State private var importError: String?
    @State private var showError = false
    var onTuneImported: ((TuneModel) -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Импорт файлов")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Выберите ABC файл для загрузки")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showPicker = true
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Выбрать файл")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.8),
                            Color(red: 0.3, green: 0.5, blue: 0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            if !tuneManager.tunes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Загруженные мелодии")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(tuneManager.tunes) { tune in
                                TuneRowView(tune: tune, tuneManager: tuneManager)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showPicker) {
            DocumentPicker(
                allowedContentTypes: [
                    UTType(filenameExtension: "abc") ?? .data
                ],
                onDocumentPicked: { url in
                    if let tune = tuneManager.importFile(from: url) {
                        onTuneImported?(tune)
                        dismiss()
                    } else {
                        importError = "Не удалось загрузить файл"
                        showError = true
                    }
                }
            )
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError ?? "Неизвестная ошибка")
        }
    }
}

// MARK: - Tune Row View

struct TuneRowView: View {
    let tune: TuneModel
    @ObservedObject var tuneManager: TuneManager
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tune.title ?? tune.originalFileName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(tune.fileType.rawValue, systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if let key = tune.detectedKey {
                        Label(key, systemImage: "music.note.list")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .confirmationDialog(
            "Удалить мелодию?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                tuneManager.deleteTune(tune)
            }
            Button("Отмена", role: .cancel) { }
        }
    }
}

#Preview {
    FileImportView(tuneManager: TuneManager(), onTuneImported: nil)
}

