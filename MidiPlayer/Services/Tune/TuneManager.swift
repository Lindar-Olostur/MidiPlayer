//
//  TuneManager.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import Foundation
import SwiftUI

// MARK: - Tune Manager

/// Менеджер для работы с мелодиями
class TuneManager: ObservableObject {
    @Published var tunes: [TuneModel] = []
    @Published var currentTuneId: UUID?
    
    private let tunesDirectory: URL
    private let metadataURL: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        tunesDirectory = documentsPath.appendingPathComponent("tunes")
        metadataURL = documentsPath.appendingPathComponent("metadata/tunes.json")
        
        createDirectoriesIfNeeded()
        loadTunes()
    }
    
    // MARK: - File Management
    
    /// Загружает файл с устройства
    func importFile(from url: URL) -> TuneModel? {
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "mid" || fileExtension == "abc" else { return nil }
        
        let id = UUID()
        let fileName = "tune_\(id.uuidString).\(fileExtension)"
        let destinationURL = tunesDirectory.appendingPathComponent(fileName)
        
        do {
            // Копируем файл
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Создаём модель
            let sourceType: SourceType = fileExtension == "mid" ? .midi : .abc
            var tune = TuneModel(
                id: id,
                fileName: fileName,
                fileType: sourceType,
                originalFileName: url.lastPathComponent,
                dateAdded: Date()
            )
            
            // Парсим метаданные
            if sourceType == .midi {
                if let info = MIDIParser.parse(url: destinationURL) {
                    tune.tempo = info.tempo
                    tune.detectedKey = KeyDetector.detectKey(from: info.allNotes)
                    tune.endMeasure = info.totalMeasures
                    tune.title = url.deletingPathExtension().lastPathComponent
                }
            } else {
                if let abcTunes = ABCParser.parseFile(url: destinationURL), !abcTunes.isEmpty {
                    let firstTune = abcTunes[0]
                    tune.title = firstTune.title
                    tune.detectedKey = firstTune.key
                    tune.selectedTuneIndex = 0
                }
            }
            
            tunes.append(tune)
            saveTunes()
            return tune
            
        } catch {
            print("❌ Failed to import file: \(error)")
            return nil
        }
    }
    
    /// Удаляет мелодию
    func deleteTune(_ tune: TuneModel) {
        // Удаляем файл
        let fileURL = tunesDirectory.appendingPathComponent(tune.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        // Удаляем из списка
        tunes.removeAll { $0.id == tune.id }
        if currentTuneId == tune.id {
            currentTuneId = nil
        }
        saveTunes()
    }
    
    /// Получает URL файла мелодии
    func fileURL(for tune: TuneModel) -> URL {
        tunesDirectory.appendingPathComponent(tune.fileName)
    }
    
    /// Получает текущую мелодию
    func currentTune() -> TuneModel? {
        guard let tuneId = currentTuneId else { return nil }
        return tunes.first { $0.id == tuneId }
    }
    
    // MARK: - Settings Management
    
    /// Сохраняет настройки для текущей мелодии
    func saveSettings(for tuneId: UUID, transpose: Int? = nil, tempo: Double? = nil, whistleKey: WhistleKey? = nil, selectedKey: String? = nil, startMeasure: Int? = nil, endMeasure: Int? = nil, selectedTuneIndex: Int? = nil) {
        guard let index = tunes.firstIndex(where: { $0.id == tuneId }) else { return }
        
        if let transpose = transpose {
            tunes[index].transpose = transpose
        }
        if let tempo = tempo {
            tunes[index].tempo = tempo
        }
        if let whistleKey = whistleKey {
            tunes[index].whistleKey = whistleKey
        }
        if let selectedKey = selectedKey {
            tunes[index].selectedKey = selectedKey
        }
        if let startMeasure = startMeasure {
            tunes[index].startMeasure = startMeasure
        }
        if let endMeasure = endMeasure {
            tunes[index].endMeasure = endMeasure
        }
        if let selectedTuneIndex = selectedTuneIndex {
            tunes[index].selectedTuneIndex = selectedTuneIndex
        }
        
        saveTunes()
    }
    
    /// Сохраняет полные настройки мелодии
    func saveFullSettings(_ tune: TuneModel) {
        guard let index = tunes.firstIndex(where: { $0.id == tune.id }) else { return }
        tunes[index] = tune
        saveTunes()
    }
    
    /// Загружает настройки мелодии
    func loadSettings(for tuneId: UUID) -> TuneModel? {
        tunes.first { $0.id == tuneId }
    }
    
    /// Сохраняет отредактированные ноты
    func saveEditedNotes(_ notes: [MIDINote], for tuneId: UUID) {
        guard let index = tunes.firstIndex(where: { $0.id == tuneId }) else { return }
        tunes[index].editedNotes = notes
        tunes[index].isEdited = true
        saveTunes()
    }
    
    // MARK: - Persistence
    
    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: tunesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: metadataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    
    private func loadTunes() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([TuneModel].self, from: data) else {
            print("📁 No saved tunes found, starting fresh")
            return
        }
        tunes = decoded
        print("📁 Loaded \(tunes.count) tunes from storage")
    }
    
    private func saveTunes() {
        guard let data = try? JSONEncoder().encode(tunes) else {
            print("❌ Failed to encode tunes")
            return
        }
        do {
            try data.write(to: metadataURL)
            print("💾 Saved \(tunes.count) tunes to storage")
        } catch {
            print("❌ Failed to save tunes: \(error)")
        }
    }
}

