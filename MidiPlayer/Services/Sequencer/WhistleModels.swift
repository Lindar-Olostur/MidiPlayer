//
//  WhistleModels.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import Foundation
import SwiftUI

// MARK: - Whistle Key (строй вистла)

/// Строй вистла от высокого Eb до E (хроматически)
enum WhistleKey: String, CaseIterable, Codable {
    // От высокого к низкому
    case Eb = "Eb"
    case D_high = "D"
    case Csharp = "C#"
    case C = "C"
    case B = "B"
    case Bb = "Bb"
    case A = "A"
    case Ab = "Ab"
    case G = "G"
    case Fsharp = "F#"
    case F = "F"
    case E = "E"
    
    /// Название для отображения
    var displayName: String {
        switch self {
        case .Eb: return "E♭"
        case .D_high: return "D"
        case .Csharp: return "C#"
        case .C: return "C"
        case .B: return "B"
        case .Bb: return "B♭"
        case .A: return "A"
        case .Ab: return "A♭"
        case .G: return "G"
        case .Fsharp: return "F#"
        case .F: return "F"
        case .E: return "E"
        }
    }
    
    /// Номер ноты тоники (0-11, где C=0, D=2, и т.д.)
    var tonicNote: Int {
        switch self {
        case .Eb:      return 3   // Eb
        case .D_high:  return 2   // D
        case .Csharp:  return 1   // C#
        case .C:       return 0   // C
        case .B:       return 11  // B
        case .Bb:      return 10  // Bb
        case .A:       return 9   // A
        case .Ab:      return 8   // Ab
        case .G:       return 7   // G
        case .Fsharp:  return 6   // F#
        case .F:       return 5   // F
        case .E:       return 4   // E
        }
    }

    /// Диапазон свистля в MIDI нотах (minPitch, maxPitch)
    /// Реалистичные диапазоны для tin whistles (высокие октавы)
    var pitchRange: (min: UInt8, max: UInt8) {
        switch self {
        case .D_high:  return (62, 83)  // D4 - B5
        case .Csharp:  return (61, 82)  // C#4 - A#5
        case .C:       return (60, 81)  // C4 - A5
        case .B:       return (59, 80)  // B3 - G#5
        case .Bb:      return (58, 79)  // A#3 - G5
        case .A:       return (57, 78)  // A3 - F#5
        case .Ab:      return (56, 77)  // G#3 - F5
        case .G:       return (55, 76)  // G3 - E5
        case .Fsharp:  return (66, 87)  // F#4 - D#6
        case .F:       return (65, 86)  // F4 - D6
        case .E:       return (64, 85)  // E4 - C#6
        case .Eb:      return (63, 84)  // Eb4 - C6
        }
    }
}

// MARK: - Whistle Scale Degree

enum PlayableState {
    case basic, intermediate, advanced, expert
}

enum WhistleScaleDegree: String, CaseIterable {
    case I = "I"
    case II = "II"
    case III = "III"
    case IV = "IV"
    case V = "V"
    case VI = "VI"
    case flatVII = "♭VII"
    case VII = "VII"
    case I2 = "I²"
    case II2 = "II²"
    case III2 = "III²"
    case IV2 = "IV²"
    case V2 = "V²"
    case VI2 = "VI²"

    var imageName: String { rawValue }
    
    /// Цвет на основе ступени (аналогично noteColor в PianoRollCursorView)
    var color: Color {
        // Получаем индекс ступени для вычисления hue
        let degreeIndex: Int
        switch self {
        case .I: degreeIndex = 0
        case .II: degreeIndex = 1
        case .III: degreeIndex = 2
        case .IV: degreeIndex = 3
        case .V: degreeIndex = 4
        case .VI: degreeIndex = 5
        case .flatVII: degreeIndex = 6
        case .VII: degreeIndex = 7
        case .I2: degreeIndex = 8
        case .II2: degreeIndex = 9
        case .III2: degreeIndex = 10
        case .IV2: degreeIndex = 11
        case .V2: degreeIndex = 12
        case .VI2: degreeIndex = 13
        }
        
        // Используем похожую логику с hue, как в noteColor
        let hue = Double(degreeIndex % 12) / 12.0
        return Color(hue: hue * 0.3 + 0.55, saturation: 0.7, brightness: 0.75)
    }
    
    var holesArray: [HoleState] {
        switch self {
        case .I: [.closed, .closed, .closed, .closed, .closed, .closed]
        case .II: [.closed, .closed, .closed, .closed, .closed, .opened]
        case .III: [.closed, .closed, .closed, .closed, .opened, .opened]
        case .IV: [.closed, .closed, .closed, .opened, .opened, .opened]
        case .V: [.closed, .closed, .opened, .opened, .opened, .opened]
        case .VI: [.closed, .opened, .opened, .opened, .opened, .opened]
        case .flatVII: [.opened, .closed, .opened, .opened, .opened, .opened] //ALT
        case .VII: [.opened, .opened, .opened, .opened, .opened, .opened]
        case .I2: [.closed, .closed, .closed, .closed, .closed, .closed, .closed] //ALT
        case .II2: [.closed, .closed, .closed, .closed, .closed, .opened, .closed]
        case .III2: [.closed, .closed, .closed, .closed, .opened, .opened, .closed]
        case .IV2: [.closed, .closed, .closed, .opened, .opened, .opened, .closed]
        case .V2: [.closed, .closed, .opened, .opened, .opened, .opened, .closed]
        case .VI2: [.closed, .opened, .opened, .opened, .opened, .opened, .closed]
        }
    }
    
    var level: PlayableState {
        switch self {
        case .I: .basic
        case .II: .basic
        case .III: .basic
        case .IV: .basic
        case .V: .basic
        case .VI: .basic
        case .flatVII: .basic
        case .VII: .basic
        case .I2: .basic
        case .II2: .basic
        case .III2: .basic
        case .IV2: .basic
        case .V2: .basic
        case .VI2: .basic
        }
    }
}

// MARK: - Pitch to Degree Converter

struct WhistleConverter {
    
    /// Преобразует MIDI pitch в аппликатуру на выбранном вистле
    /// Возвращает nil если нота не может быть сыграна на данном вистле (хроматическая нота)
    static func pitchToFingering(_ pitch: UInt8, whistleKey: WhistleKey) -> WhistleScaleDegree? {
        let midiPitch = Int(pitch)
        let pitchNote = midiPitch % 12  // Нота без октавы (0-11)
        let whistleTonicNote = whistleKey.tonicNote

        // Вычисляем интервал от тоники вистла (0-11)
        var interval = pitchNote - whistleTonicNote
        if interval < 0 {
            interval += 12
        }

        // Определяем октаву: вторая октава начинается с тоники следующей октавы
        // Для D whistle: тоника D4 (62), вторая октава с D5 (74) и выше
        // Вычисляем октаву тоники: (pitchRange.min - tonicNote) / 12 + 1
        let tonicOctave = (Int(whistleKey.pitchRange.min) - whistleTonicNote) / 12 + 1
        let upperOctaveThreshold = whistleTonicNote + 12 * tonicOctave
        let isUpperOctave = midiPitch >= upperOctaveThreshold

        // Только диатонические ступени мажорной гаммы
        switch interval {
        case 0:  return isUpperOctave ? .I2 : .I
        case 2:  return isUpperOctave ? .II2 : .II
        case 4:  return isUpperOctave ? .III2 : .III
        case 5:  return isUpperOctave ? .IV2 : .IV
        case 7:  return isUpperOctave ? .V2 : .V
        case 9:  return isUpperOctave ? .VI2 : .VI
        case 10: return .flatVII  // ♭VII - всегда одинаково (все клапаны открыты)
        case 11: return .VII      // VII - всегда одинаково (все клапаны открыты)
        default: return nil  // Хроматические ноты
        }
    }
    
    static func pitchToNoteName(_ pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        return "\(noteNames[note])\(octave)"
    }

    /// Структура для хранения информации о playable варианте тональности
    public struct PlayableKeyVariant {
        let key: String           // Название тональности
        let melodyMin: UInt8      // Минимальная нота мелодии
        let transpose: Int        // Транспонирование
    }

    /// Находит все тональности, в которых мелодия может быть полностью сыграна на данном вистле
    /// Для каждой тональности выбирается вариант с самым низким диапазоном мелодии
    /// - Parameters:
    ///   - notes: оригинальные ноты мелодии
    ///   - whistleKey: строй вистла
    ///   - baseKey: базовая тональность мелодии (для расчета результирующих тональностей)
    /// - Returns: массив уникальных тональностей мелодии, где все ноты playable на данном вистле и в его диапазоне
    /// TODO еще момент: есть мелодии у которых очень узкий диапазон и на одном вистле их можно сыграть как в пеовой октаве так и с передувом. но в предложенных тональностях только один вариант. нам надо различать такие варианты и показывать оба
    static func findPlayableKeys(for notes: [MIDINote], whistleKey: WhistleKey, baseKey: String) -> [String] {
        let variants = findPlayableKeyVariants(for: notes, whistleKey: whistleKey, baseKey: baseKey)
        return variants.map { $0.key }
    }

    /// Находит все варианты тональностей с информацией о транспонировании
    /// Для каждой тональности выбирается вариант с самым низким диапазоном мелодии
    static func findPlayableKeyVariants(for notes: [MIDINote], whistleKey: WhistleKey, baseKey: String) -> [PlayableKeyVariant] {
        var playableVariants = [PlayableKeyVariant]()

        // Получаем диапазон свистля
        let pitchRange = whistleKey.pitchRange
        let (minPitch, maxPitch) = (pitchRange.min, pitchRange.max)

        // Извлекаем базовую ноту из тональности
        let baseNoteIndex = noteNameToIndex(baseKey)

        print("🔍 Поиск playable тональностей для \(notes.count) нот")
        print("🎵 Свистель: \(whistleKey.displayName) (диапазон: \(minPitch)-\(maxPitch))")
        print("🎼 Базовая тональность: \(baseKey) (индекс: \(baseNoteIndex))")
        print("")

        // Проверяем каждое возможное транспонирование (-12 до +12 полутонов)
        for transpose in -12...12 {
            // Проверяем, playable ли все ноты при этом транспонировании и находятся ли они в диапазоне
            let allPlayableAndInRange = notes.allSatisfy { note in
                let transposedPitch = UInt8(max(0, min(127, Int(note.pitch) + transpose)))

                // Проверяем, что нота playable на свистле
                guard let _ = pitchToFingering(transposedPitch, whistleKey: whistleKey) else {
                    return false
                }

                // Проверяем, что нота находится в диапазоне свистля
                return transposedPitch >= minPitch && transposedPitch <= maxPitch
            }

            if allPlayableAndInRange {
                // Рассчитываем результирующую тональность мелодии
                let newNoteIndex = (baseNoteIndex + transpose + 12) % 12
                let newKey = indexToNoteName(newNoteIndex, isMinor: baseKey.lowercased().hasSuffix("m"))

                // Вычисляем диапазон транспонированной мелодии
                let transposedPitches = notes.map { UInt8(max(0, min(127, Int($0.pitch) + transpose))) }
                let melodyMin = transposedPitches.min() ?? 0

                // Сохраняем вариант
                playableVariants.append(PlayableKeyVariant(key: newKey, melodyMin: melodyMin, transpose: transpose))

                // Отладка только для успешных случаев
                print("🎯 УСПЕХ! Транспонирование \(transpose > 0 ? "+" : "")\(transpose): тональность \(newKey)")
                print("   Диапазон вистла: \(minPitch)-\(maxPitch), Диапазон мелодии: \(melodyMin)-\(transposedPitches.max() ?? 0)")
            }
        }

        // Группируем варианты по тональности и выбираем для каждой самый низкий диапазон мелодии
        var bestVariants = [String: PlayableKeyVariant]()
        print("\n🎯 Группировка вариантов по тональностям:")
        for variant in playableVariants.sorted(by: { $0.key < $1.key }) {
            print("   Найден: \(variant.key) (transpose: \(variant.transpose > 0 ? "+" : "")\(variant.transpose), min: \(variant.melodyMin))")

            if let existing = bestVariants[variant.key] {
                // Если уже есть вариант для этой тональности, выбираем с более низким диапазоном
                print("   Сравнение: существующий min=\(existing.melodyMin), новый min=\(variant.melodyMin)")
                if variant.melodyMin < existing.melodyMin {
                    print("   ✅ Заменяем на более низкий вариант!")
                    bestVariants[variant.key] = variant
                } else {
                    print("   ❌ Оставляем существующий (он ниже или равен)")
                }
            } else {
                bestVariants[variant.key] = variant
                print("   ➕ Добавлен первый вариант")
            }
        }

        print("\n📊 Выбраны оптимальные варианты:")
        for (key, variant) in bestVariants.sorted(by: { $0.key < $1.key }) {
            print("   \(key): транспонирование \(variant.transpose > 0 ? "+" : "")\(variant.transpose), диапазон от \(variant.melodyMin)")
        }
        print("")

        // Сортируем тональности по близости к тонике вистла
        let whistleTonicIndex = whistleKey.tonicNote

        // Функция для вычисления циклического расстояния между двумя индексами нот
        func circularDistance(_ index1: Int, _ index2: Int) -> Int {
            let diff = abs(index1 - index2)
            return min(diff, 12 - diff)
        }

        // Получаем уникальные варианты и сортируем по расстоянию от тоники вистла
        let sortedVariants = bestVariants.values.sorted { variant1, variant2 in
            let index1 = noteNameToIndex(variant1.key)
            let index2 = noteNameToIndex(variant2.key)
            let distance1 = circularDistance(index1, whistleTonicIndex)
            let distance2 = circularDistance(index2, whistleTonicIndex)

            // Если расстояния равны, сортируем по индексу
            if distance1 == distance2 {
                return index1 < index2
            }
            return distance1 < distance2
        }

        return sortedVariants
    }

    /// Преобразует название ноты в индекс (C=0, C#=1, D=2, ...)
    private static func noteNameToIndex(_ noteName: String) -> Int {
        let normalizedName = noteName.replacingOccurrences(of: "♭", with: "b")
        let noteMap: [String: Int] = [
            "C": 0, "C#": 1, "Db": 1, "C♯": 1, "D": 2, "D#": 3, "Eb": 3, "D♯": 3, "E": 4,
            "F": 5, "F#": 6, "Gb": 6, "F♯": 6, "G": 7, "G#": 8, "Ab": 8, "G♯": 8, "A": 9,
            "A#": 10, "Bb": 10, "A♯": 10, "B": 11
        ]

        // Извлекаем ноту из тональности (убираем суффиксы)
        var baseNote = normalizedName
        for suffix in ["m", "min", "maj", "dor", "phr", "lyd", "mix", "loc"] {
            if baseNote.lowercased().hasSuffix(suffix) {
                baseNote = String(baseNote.dropLast(suffix.count))
                break
            }
        }

        return noteMap[baseNote] ?? 0
    }

    /// Преобразует индекс в название ноты
    /// Использует ту же систему обозначений, что и вистлы: бемоли для Eb, Bb, Ab, диезы для C#, F#
    private static func indexToNoteName(_ index: Int, isMinor: Bool) -> String {
        let noteNames = ["C", "C#", "D", "E♭", "E", "F", "F#", "G", "A♭", "A", "B♭", "B"]
        let noteName = noteNames[(index + 12) % 12]
        return isMinor ? "\(noteName)m" : noteName
    }

}

// MARK: - Key Converter

extension WhistleKey {
    /// Преобразует тональность мелодии (например "Dmaj", "Ador", "G") в строй вистла
    static func from(tuneKey: String) -> WhistleKey {
        let key = tuneKey.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !key.isEmpty else { return .D_high }
        
        let firstChar = key.prefix(1)
        var noteName = String(firstChar)
        
        if key.count >= 2 {
            let second = key[key.index(key.startIndex, offsetBy: 1)]
            if second == "#" {
                noteName += "#"
            } else if second == "B" && key.prefix(2) != "BB" {
                // Проверяем что это бемоль, а не начало "BB" или "BMAJ"
                if key.hasPrefix("BB") || key.hasPrefix("BM") {
                    noteName = "B"
                }
            }
        }
        
        switch noteName {
        case "EB", "E♭": return .Eb
        case "D": return .D_high
        case "C#", "DB", "D♭": return .Csharp
        case "C": return .C
        case "B": return .B
        case "BB", "B♭", "A#": return .Bb
        case "A": return .A
        case "AB", "A♭", "G#": return .Ab
        case "G": return .G
        case "F#", "GB", "G♭": return .Fsharp
        case "F": return .F
        case "E": return .E
        default: return .D_high
        }
    }
}

