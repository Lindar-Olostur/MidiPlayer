//
//  TuneModel.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import Foundation

// MARK: - Tune Model

/// Модель мелодии с настройками
struct TuneModel: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileType: SourceType
    let originalFileName: String  // Имя файла при загрузке
    let dateAdded: Date
    
    // Настройки воспроизведения
    var transpose: Int = 0
    var tempo: Double = 120
    var whistleKey: WhistleKey = .D_high
    var selectedKey: String?  // Выбранная тональность из playable keys
    
    // Диапазон воспроизведения
    var startMeasure: Int = 1
    var endMeasure: Int = 1
    
    // Для ABC файлов
    var selectedTuneIndex: Int = 0
    
    // Метаданные (из файла)
    var title: String?
    var detectedKey: String?
    
    // Флаг редактирования
    var isEdited: Bool = false
    var editedNotes: [MIDINote]?  // Для будущего редактирования
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, fileName, fileType, originalFileName, dateAdded
        case transpose, tempo, whistleKey, selectedKey
        case startMeasure, endMeasure, selectedTuneIndex
        case title, detectedKey, isEdited
        // editedNotes не сохраняем в JSON (слишком большой)
    }
    
    init(id: UUID = UUID(),
         fileName: String,
         fileType: SourceType,
         originalFileName: String,
         dateAdded: Date = Date(),
         transpose: Int = 0,
         tempo: Double = 120,
         whistleKey: WhistleKey = .D_high,
         selectedKey: String? = nil,
         startMeasure: Int = 1,
         endMeasure: Int = 1,
         selectedTuneIndex: Int = 0,
         title: String? = nil,
         detectedKey: String? = nil,
         isEdited: Bool = false,
         editedNotes: [MIDINote]? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.originalFileName = originalFileName
        self.dateAdded = dateAdded
        self.transpose = transpose
        self.tempo = tempo
        self.whistleKey = whistleKey
        self.selectedKey = selectedKey
        self.startMeasure = startMeasure
        self.endMeasure = endMeasure
        self.selectedTuneIndex = selectedTuneIndex
        self.title = title
        self.detectedKey = detectedKey
        self.isEdited = isEdited
        self.editedNotes = editedNotes
    }
}

// MARK: - MIDINote Codable Extension

extension MIDINote: Codable {
    enum CodingKeys: String, CodingKey {
        case pitch, velocity, startBeat, duration, channel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pitch = try container.decode(UInt8.self, forKey: .pitch)
        velocity = try container.decode(UInt8.self, forKey: .velocity)
        startBeat = try container.decode(Double.self, forKey: .startBeat)
        duration = try container.decode(Double.self, forKey: .duration)
        channel = try container.decode(UInt8.self, forKey: .channel)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pitch, forKey: .pitch)
        try container.encode(velocity, forKey: .velocity)
        try container.encode(startBeat, forKey: .startBeat)
        try container.encode(duration, forKey: .duration)
        try container.encode(channel, forKey: .channel)
    }
}

