//
//  ABCParser.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 28.11.2025.
//

import Foundation

// MARK: - ABC Tune Model

struct ABCTune: Identifiable {
    let id: Int                    // X: номер
    let title: String              // T: название
    let meter: String              // M: размер (4/4, 6/8)
    let defaultLength: Double      // L: базовая длина (1/8 = 0.5 бита)
    let key: String                // K: тональность
    let notes: [MIDINote]          // Распарсенные ноты
    let totalBeats: Double
    let beatsPerMeasure: Int
}

// MARK: - ABC Parser

class ABCParser {
    
    // Базовые MIDI номера нот (для октавы 4, C4 = 60)
    private static let noteBasesMajor: [Character: Int] = [
        "C": 60, "D": 62, "E": 64, "F": 65, "G": 67, "A": 69, "B": 71
    ]
    
    // Модификаторы для тональностей (какие ноты # или b по умолчанию)
    private static let keySignatures: [String: Set<Character>] = [
        "C": [],
        "G": ["F"],           // F#
        "D": ["F", "C"],      // F#, C#
        "A": ["F", "C", "G"], // F#, C#, G#
        "E": ["F", "C", "G", "D"],
        "B": ["F", "C", "G", "D", "A"],
        "F#": ["F", "C", "G", "D", "A", "E"],
        "F": [],              // Bb - обрабатываем бемоли отдельно
        "Bb": [],
        "Eb": [],
        "Ab": [],
    ]
    
    private static let keyFlats: [String: Set<Character>] = [
        "F": ["B"],
        "Bb": ["B", "E"],
        "Eb": ["B", "E", "A"],
        "Ab": ["B", "E", "A", "D"],
    ]
    
    /// Парсит ABC файл и возвращает массив мелодий
    static func parseFile(url: URL) -> [ABCTune]? {
        print("ABCParser: Trying to read file at \(url.path)")
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("ABCParser: Failed to read file content")
            return nil
        }
        
        print("ABCParser: File content length: \(content.count) characters")
        
        let tunes = parseContent(content)
        print("ABCParser: Parsed \(tunes.count) tunes")
        
        return tunes.isEmpty ? nil : tunes
    }
    
    /// Парсит ABC контент
    static func parseContent(_ content: String) -> [ABCTune] {
        var tunes: [ABCTune] = []
        var currentTune: [String: String] = [:]
        var currentBody: String = ""
        var inBody = false
        
        // Нормализуем переносы строк (Windows \r\n -> \n)
        let normalizedContent = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let lines = normalizedContent.components(separatedBy: "\n")
        print("ABCParser: Total lines: \(lines.count)")
        
        for (lineNum, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Пустая строка - разделитель между мелодиями
            if trimmed.isEmpty {
                if inBody {
                    print("ABCParser: Empty line at \(lineNum), trying to build tune with headers: \(currentTune.keys.sorted())")
                    if let tune = buildTune(from: currentTune, body: currentBody) {
                        tunes.append(tune)
                        print("ABCParser: Built tune #\(tune.id): \(tune.title)")
                    } else {
                        print("ABCParser: Failed to build tune from headers: \(currentTune)")
                    }
                }
                currentTune = [:]
                currentBody = ""
                inBody = false
                continue
            }
            
            // Заголовок (X:, T:, M:, L:, K:, etc) - проверяем что это буква + двоеточие
            if trimmed.count >= 2 {
                let firstChar = trimmed[trimmed.startIndex]
                let secondChar = trimmed[trimmed.index(trimmed.startIndex, offsetBy: 1)]
                
                if firstChar.isLetter && secondChar == ":" {
                    let key = String(firstChar)
                    let value = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                    currentTune[key] = value
                    
                    // K: означает начало тела мелодии
                    if key == "K" {
                        inBody = true
                        print("ABCParser: Found K: at line \(lineNum), entering body mode")
                    }
                    continue
                }
            }
            
            if inBody {
                // Это строка с нотами
                currentBody += trimmed + " "
            }
        }
        
        // Последняя мелодия
        if inBody {
            print("ABCParser: End of file, trying to build last tune with headers: \(currentTune.keys.sorted())")
            if let tune = buildTune(from: currentTune, body: currentBody) {
                tunes.append(tune)
                print("ABCParser: Built last tune #\(tune.id): \(tune.title)")
            }
        }
        
        return tunes
    }
    
    /// Создаёт ABCTune из распарсенных данных
    private static func buildTune(from headers: [String: String], body: String) -> ABCTune? {
        guard let xStr = headers["X"] else {
            print("ABCParser buildTune: No X header found")
            return nil
        }
        guard let x = Int(xStr) else {
            print("ABCParser buildTune: X header '\(xStr)' is not a valid integer")
            return nil
        }
        
        let title = headers["T"] ?? "Untitled"
        let meter = headers["M"] ?? "4/4"
        let lengthStr = headers["L"] ?? "1/8"
        let key = headers["K"] ?? "C"
        
        // Парсим размер (4/4 -> 4 бита в такте)
        let beatsPerMeasure = parseMeter(meter)
        
        // Парсим базовую длину (1/8 -> 0.5 бита)
        let defaultLength = parseLength(lengthStr)
        
        // Парсим ноты
        let notes = parseNotes(body: body, key: key, defaultLength: defaultLength)
        
        let totalBeats = notes.map { $0.endBeat }.max() ?? 0
        
        return ABCTune(
            id: x,
            title: title,
            meter: meter,
            defaultLength: defaultLength,
            key: key,
            notes: notes,
            totalBeats: totalBeats,
            beatsPerMeasure: beatsPerMeasure
        )
    }
    
    /// Парсит размер такта
    private static func parseMeter(_ meter: String) -> Int {
        let parts = meter.split(separator: "/")
        if parts.count == 2, let numerator = Int(parts[0]) {
            return numerator
        }
        return 4
    }
    
    /// Парсит базовую длину ноты
    private static func parseLength(_ length: String) -> Double {
        let parts = length.split(separator: "/")
        if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]) {
            // 1/8 означает 0.5 бита (восьмая = половина четверти)
            return (num / den) * 4.0
        }
        return 0.5 // По умолчанию 1/8
    }
    
    /// Парсит ноты из тела мелодии с поддержкой реприз, триолей и затактов
    private static func parseNotes(body: String, key: String, defaultLength: Double) -> [MIDINote] {
        // Определяем ключевые знаки
        let keyBase = key.replacingOccurrences(of: "maj", with: "")
                        .replacingOccurrences(of: "min", with: "")
                        .trimmingCharacters(in: .whitespaces)
        let sharps = keySignatures[keyBase] ?? []
        let flats = keyFlats[keyBase] ?? []
        
        // Сначала разворачиваем репризы
        let expandedBody = expandRepeats(body)
        
        // Теперь парсим развёрнутую строку
        var notes: [MIDINote] = []
        var currentBeat: Double = 0
        var i = expandedBody.startIndex
        var activeAccidentals: [Character: Int] = [:]
        
        // Триоли: (3 означает 3 ноты за время 2
        var tupletRemaining: Int = 0      // сколько нот осталось в триоли
        var tupletRatio: Double = 1.0     // множитель длительности (2/3 для триоли)
        
        // Для отслеживания затакта
        var foundFirstBar = false
        var pickupNotes: [MIDINote] = []
        
        while i < expandedBody.endIndex {
            let char = expandedBody[i]
            
            // Пропускаем пробелы
            if char.isWhitespace {
                i = expandedBody.index(after: i)
                continue
            }
            
            // Тактовая черта - сбрасываем случайные знаки
            if char == "|" {
                activeAccidentals = [:]
                
                if !foundFirstBar {
                    // Это первая тактовая черта - всё до неё это затакт
                    foundFirstBar = true
                    pickupNotes = notes
                    notes = []
                    currentBeat = 0
                }
                
                i = expandedBody.index(after: i)
                // Пропускаем любые символы после |
                while i < expandedBody.endIndex && !expandedBody[i].isLetter && !expandedBody[i].isWhitespace && !"^_=({".contains(expandedBody[i]) {
                    i = expandedBody.index(after: i)
                }
                continue
            }
            
            // Пропускаем структурные символы
            if [":", "[", "]"].contains(char) {
                i = expandedBody.index(after: i)
                continue
            }
            
            // Аккордовые символы в кавычках - пропускаем
            if char == "\"" {
                i = expandedBody.index(after: i)
                while i < expandedBody.endIndex && expandedBody[i] != "\"" {
                    i = expandedBody.index(after: i)
                }
                if i < expandedBody.endIndex {
                    i = expandedBody.index(after: i)
                }
                continue
            }
            
            // Grace notes в фигурных скобках - пропускаем
            if char == "{" {
                while i < expandedBody.endIndex && expandedBody[i] != "}" {
                    i = expandedBody.index(after: i)
                }
                if i < expandedBody.endIndex {
                    i = expandedBody.index(after: i)
                }
                continue
            }
            
            // Триоль/туплет (N - N нот за время N-1
            if char == "(" {
                i = expandedBody.index(after: i)
                if i < expandedBody.endIndex && expandedBody[i].isNumber {
                    let n = Int(String(expandedBody[i])) ?? 3
                    tupletRemaining = n
                    // (3 = 3 ноты за время 2, (2 = 2 за 3, и т.д.
                    tupletRatio = Double(n - 1) / Double(n)
                    i = expandedBody.index(after: i)
                }
                continue
            }
            
            // Тильда (орнамент) - пропускаем
            if char == "~" {
                i = expandedBody.index(after: i)
                continue
            }
            
            // Пауза
            if char == "z" || char == "Z" {
                var duration = defaultLength
                i = expandedBody.index(after: i)
                let (newIndex, lengthMod) = parseLengthModifier(expandedBody, from: i)
                i = newIndex
                duration *= lengthMod
                
                // Применяем триольный множитель
                if tupletRemaining > 0 {
                    duration *= tupletRatio
                    tupletRemaining -= 1
                }
                
                currentBeat += duration
                continue
            }
            
            // Случайные знаки
            var accidental: Int = 0
            if char == "^" {
                accidental = 1
                i = expandedBody.index(after: i)
                if i < expandedBody.endIndex && expandedBody[i] == "^" {
                    accidental = 2
                    i = expandedBody.index(after: i)
                }
            } else if char == "_" {
                accidental = -1
                i = expandedBody.index(after: i)
                if i < expandedBody.endIndex && expandedBody[i] == "_" {
                    accidental = -2
                    i = expandedBody.index(after: i)
                }
            } else if char == "=" {
                accidental = 0
                i = expandedBody.index(after: i)
            }
            
            guard i < expandedBody.endIndex else { break }
            let noteChar = expandedBody[i]
            
            if let basePitch = getMIDIPitch(for: noteChar, sharps: sharps, flats: flats, accidentals: &activeAccidentals, currentAccidental: accidental) {
                i = expandedBody.index(after: i)
                var pitch = basePitch
                
                // Октавные модификаторы
                while i < expandedBody.endIndex {
                    if expandedBody[i] == "'" {
                        pitch += 12
                        i = expandedBody.index(after: i)
                    } else if expandedBody[i] == "," {
                        pitch -= 12
                        i = expandedBody.index(after: i)
                    } else {
                        break
                    }
                }
                
                // Длина ноты
                var duration = defaultLength
                let (newIndex, lengthMod) = parseLengthModifier(expandedBody, from: i)
                i = newIndex
                duration *= lengthMod
                
                // Применяем триольный множитель
                if tupletRemaining > 0 {
                    duration *= tupletRatio
                    tupletRemaining -= 1
                }
                
                let note = MIDINote(
                    pitch: UInt8(max(0, min(127, pitch))),
                    velocity: 80,
                    startBeat: currentBeat,
                    duration: duration,
                    channel: 0
                )
                notes.append(note)
                currentBeat += duration
            } else {
                i = expandedBody.index(after: i)
            }
        }
        
        // Добавляем затакт в начало
        // Затакт просто добавляется перед основными нотами
        if !pickupNotes.isEmpty {
            // Вычисляем длительность затакта
            let pickupDuration = pickupNotes.map { $0.endBeat }.max() ?? 0
            
            // Сдвигаем основные ноты на длительность затакта
            let shiftedNotes = notes.map { note in
                MIDINote(
                    pitch: note.pitch,
                    velocity: note.velocity,
                    startBeat: note.startBeat + pickupDuration,
                    duration: note.duration,
                    channel: note.channel
                )
            }
            
            // Объединяем: затакт + сдвинутые основные ноты
            notes = pickupNotes + shiftedNotes
        }
        
        return notes
    }
    
    /// Разворачивает репризы и альтернативные концовки
    private static func expandRepeats(_ body: String) -> String {
        var result = ""
        var i = body.startIndex
        
        // Разбиваем на секции по ||
        let sections = body.components(separatedBy: "||")
        
        for section in sections {
            let expanded = expandSection(section)
            result += expanded
        }
        
        return result
    }
    
    /// Разворачивает одну секцию с репризами
    private static func expandSection(_ section: String) -> String {
        // Ищем паттерны реприз: |: ... :| или |: ... |1 ... :|2 ...
        var result = ""
        var remaining = section
        
        while !remaining.isEmpty {
            // Ищем начало репризы |:
            if let repeatStartRange = remaining.range(of: "|:") {
                // Добавляем всё до начала репризы
                result += String(remaining[remaining.startIndex..<repeatStartRange.lowerBound])
                remaining = String(remaining[repeatStartRange.upperBound...])
                
                // Ищем конец репризы :| или :|2
                if let repeatEndRange = remaining.range(of: ":|") {
                    let repeatContent = String(remaining[remaining.startIndex..<repeatEndRange.lowerBound])
                    
                    // Проверяем наличие альтернативных концовок |1 и |2 (или [1 и [2)
                    let ending1Patterns = ["|1", "[1", "1"]
                    let ending2Patterns = ["|2", "[2", "2"]
                    
                    var firstEndingStart: String.Index?
                    var secondEndingStart: String.Index?
                    
                    for pattern in ending1Patterns {
                        if let range = repeatContent.range(of: pattern) {
                            firstEndingStart = range.lowerBound
                            break
                        }
                    }
                    
                    // Ищем вторую концовку после :|
                    let afterRepeat = String(remaining[repeatEndRange.upperBound...])
                    var secondEnding = ""
                    var afterSecondEnding = afterRepeat
                    
                    for pattern in ending2Patterns {
                        if afterRepeat.hasPrefix(pattern) {
                            // Вторая концовка начинается сразу после :|
                            let withoutPrefix = String(afterRepeat.dropFirst(pattern.count))
                            // Ищем конец второй концовки (следующая тактовая черта или конец)
                            if let nextBar = withoutPrefix.firstIndex(of: "|") {
                                secondEnding = String(withoutPrefix[withoutPrefix.startIndex..<nextBar])
                                afterSecondEnding = String(withoutPrefix[nextBar...])
                            } else {
                                secondEnding = withoutPrefix
                                afterSecondEnding = ""
                            }
                            break
                        }
                    }
                    
                    if let firstStart = firstEndingStart {
                        // Есть альтернативные концовки
                        let mainPart = String(repeatContent[repeatContent.startIndex..<firstStart])
                        let firstEnding = String(repeatContent[firstStart...])
                            .replacingOccurrences(of: "|1", with: "")
                            .replacingOccurrences(of: "[1", with: "")
                        
                        // Первый проход: основная часть + первая концовка
                        result += mainPart + firstEnding
                        // Второй проход: основная часть + вторая концовка
                        result += mainPart + secondEnding
                        
                        remaining = afterSecondEnding
                    } else {
                        // Простая реприза без альтернативных концовок - повторяем 2 раза
                        result += repeatContent
                        result += repeatContent
                        remaining = String(remaining[repeatEndRange.upperBound...])
                    }
                } else {
                    // Нет конца репризы - просто добавляем остаток
                    result += remaining
                    remaining = ""
                }
            } else {
                // Нет реприз - добавляем как есть
                result += remaining
                remaining = ""
            }
        }
        
        return result
    }
    
    /// Получает MIDI pitch для символа ноты
    private static func getMIDIPitch(
        for char: Character,
        sharps: Set<Character>,
        flats: Set<Character>,
        accidentals: inout [Character: Int],
        currentAccidental: Int
    ) -> Int? {
        let upperChar = char.uppercased().first!
        
        guard let basePitch = noteBasesMajor[upperChar] else {
            return nil
        }
        
        var pitch = basePitch
        
        // Строчные буквы - октава выше
        if char.isLowercase {
            pitch += 12
        }
        
        // Применяем случайный знак или ключевой знак
        if currentAccidental != 0 {
            // Явный случайный знак
            pitch += currentAccidental
            accidentals[upperChar] = currentAccidental
        } else if let activeAcc = accidentals[upperChar] {
            // Активный случайный знак в такте
            pitch += activeAcc
        } else {
            // Ключевой знак
            if sharps.contains(upperChar) {
                pitch += 1
            } else if flats.contains(upperChar) {
                pitch -= 1
            }
        }
        
        return pitch
    }
    
    /// Парсит модификатор длины ноты (2, /2, 3/2, etc)
    private static func parseLengthModifier(_ body: String, from index: String.Index) -> (String.Index, Double) {
        var i = index
        var multiplier: Double = 1.0
        
        // Цифра перед слешем (множитель)
        var numStr = ""
        while i < body.endIndex && body[i].isNumber {
            numStr.append(body[i])
            i = body.index(after: i)
        }
        
        if !numStr.isEmpty {
            multiplier = Double(numStr) ?? 1.0
        }
        
        // Слеш и делитель
        if i < body.endIndex && body[i] == "/" {
            i = body.index(after: i)
            var denStr = ""
            while i < body.endIndex && body[i].isNumber {
                denStr.append(body[i])
                i = body.index(after: i)
            }
            
            let denominator = Double(denStr) ?? 2.0
            multiplier = (numStr.isEmpty ? 1.0 : multiplier) / denominator
        }
        
        return (i, multiplier)
    }
    
    /// Конвертирует ABC tune в MIDIFileInfo для совместимости с существующим кодом
    static func toMIDIFileInfo(_ tune: ABCTune, transpose: Int = 0) -> MIDIFileInfo {
        // Применяем транспонирование к нотам для отображения
        let transposedNotes = tune.notes.map { note in
            MIDINote(
                pitch: UInt8(max(0, min(127, Int(note.pitch) + transpose))),
                velocity: note.velocity,
                startBeat: note.startBeat,
                duration: note.duration,
                channel: note.channel
            )
        }
        
        let minPitch = transposedNotes.map { $0.pitch }.min() ?? 60
        let maxPitch = transposedNotes.map { $0.pitch }.max() ?? 72
        let totalMeasures = Int(ceil(tune.totalBeats / Double(tune.beatsPerMeasure)))
        
        let trackInfo = MIDITrackInfo(
            notes: transposedNotes,
            minPitch: minPitch,
            maxPitch: maxPitch,
            totalBeats: tune.totalBeats
        )
        
        return MIDIFileInfo(
            tracks: [trackInfo],
            allNotes: transposedNotes,
            totalBeats: tune.totalBeats,
            beatsPerMeasure: tune.beatsPerMeasure,
            totalMeasures: totalMeasures,
            tempo: 120, // Стандартный темп для рилов
            minPitch: minPitch,
            maxPitch: maxPitch
        )
    }
}

