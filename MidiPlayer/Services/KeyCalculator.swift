//
//  KeyCalculator.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import Foundation

/// Сервис для расчета и работы с музыкальными тональностями
struct KeyCalculator {
    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    private static let noteMap: [String: Int] = [
        "C": 0, "C#": 1, "Db": 1, "C♯": 1, "D": 2, "D#": 3, "Eb": 3, "D♯": 3, "E": 4,
        "F": 5, "F#": 6, "Gb": 6, "F♯": 6, "G": 7, "G#": 8, "Ab": 8, "G♯": 8, "A": 9,
        "A#": 10, "Bb": 10, "A♯": 10, "B": 11
    ]

    /// Преобразует название ноты в индекс (C=0, C#=1, D=2, ...)
    static func noteNameToIndex(_ noteName: String) -> Int {
        let normalizedName = noteName.replacingOccurrences(of: "♭", with: "b")
        var baseNote = normalizedName

        // Убираем суффиксы
        for suffix in ["m", "min", "maj", "dor", "phr", "lyd", "mix", "loc"] {
            if baseNote.lowercased().hasSuffix(suffix) {
                baseNote = String(baseNote.dropLast(suffix.count))
                break
            }
        }

        return noteMap[baseNote] ?? 0
    }

    /// Вычисляет необходимое транспонирование для перехода от одной тональности к другой
    static func transposeNeeded(from currentKey: String, to targetKey: String) -> Int {
        let currentKeyIndex = noteNameToIndex(currentKey)
        let targetKeyIndex = noteNameToIndex(targetKey)
        let transposeNeeded = (targetKeyIndex - currentKeyIndex + 12) % 12
        return transposeNeeded > 6 ? transposeNeeded - 12 : transposeNeeded
    }

    /// Вычисляет текущую отображаемую тональность с учетом транспонирования
    static func currentDisplayedKey(baseKey: String, transpose: Int) -> String {
        let baseNoteIndex = noteNameToIndex(baseKey)
        let isMinor = baseKey.lowercased().hasSuffix("m")

        let newNoteIndex = (baseNoteIndex + transpose + 12) % 12
        let noteName = noteNames[newNoteIndex]

        return isMinor ? "\(noteName)m" : noteName
    }

    /// Проверяет, является ли тональность минорной
    static func isMinorKey(_ key: String) -> Bool {
        return key.lowercased().hasSuffix("m")
    }

    /// Рассчитывает оптимальное транспонирование с учетом диапазона свистля
    static func optimalTranspose(from baseKey: String, to targetKey: String, notes: [MIDINote], whistleKey: WhistleKey) -> Int {
        // Сначала рассчитываем базовое транспонирование для смены тональности
        let baseTranspose = transposeNeeded(from: baseKey, to: targetKey)

        // Получаем диапазон свистля
        let pitchRange = whistleKey.pitchRange
        let minPitch = Int(pitchRange.min)
        let maxPitch = Int(pitchRange.max)
        let optimalCenter = (minPitch + maxPitch) / 2

        // Находим оптимальный октавный сдвиг (-2..+2 октавы)
        var bestTranspose = baseTranspose
        var bestScore = 0

        for octaveShift in -2...2 {
            let totalTranspose = baseTranspose + octaveShift * 12
            var inRangeCount = 0

            for note in notes {
                let transposedPitch = Int(note.pitch) + totalTranspose
                if transposedPitch >= minPitch && transposedPitch <= maxPitch {
                    inRangeCount += 1
                }
            }

            // Также учитываем расстояние от центра диапазона
            let avgPitch = notes.map { Int($0.pitch) + totalTranspose }.reduce(0, +) / max(1, notes.count)
            let centerDistance = abs(avgPitch - optimalCenter)
            let score = inRangeCount * 100 - centerDistance

            if score > bestScore {
                bestScore = score
                bestTranspose = totalTranspose
            }
        }

        return bestTranspose
    }
}
