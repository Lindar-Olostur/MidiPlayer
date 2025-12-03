//
//  KeyCalculator.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import Foundation

/// Сервис для расчета и работы с музыкальными тональностями
struct KeyCalculator {
    // Используем ту же систему обозначений, что и вистлы: бемоли для Eb, Bb, Ab, диезы для C#, F#
    private static let noteNames = ["C", "C#", "D", "E♭", "E", "F", "F#", "G", "A♭", "A", "B♭", "B"]

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
    /// Транспонирует мелодию максимально близко к тонике вистла, обеспечивая что все ноты playable и в диапазоне
    static func optimalTranspose(from baseKey: String, to targetKey: String, notes: [MIDINote], whistleKey: WhistleKey) -> Int {
        // Сначала рассчитываем базовое транспонирование для смены тональности
        let baseTranspose = transposeNeeded(from: baseKey, to: targetKey)

        // Получаем диапазон свистля
        let pitchRange = whistleKey.pitchRange
        let minPitch = Int(pitchRange.min)
        let maxPitch = Int(pitchRange.max)
        let rangeCenter = (minPitch + maxPitch) / 2
        
        // Находим оптимальную октаву тоники вистла
        // Тоника вистла должна быть близко к центру диапазона для оптимального звучания
        let whistleTonicNote = whistleKey.tonicNote
        
        // Находим октаву тоники вистла, которая ближе всего к центру диапазона
        var optimalTonicPitch = rangeCenter
        var bestTonicDistance = Int.max
        
        for octave in 0...10 {
            let tonicPitch = whistleTonicNote + 12 * octave
            if tonicPitch >= minPitch && tonicPitch <= maxPitch {
                let distance = abs(tonicPitch - rangeCenter)
                if distance < bestTonicDistance {
                    bestTonicDistance = distance
                    optimalTonicPitch = tonicPitch
                }
            }
        }

        // Находим оптимальный октавный сдвиг
        // Проверяем все возможные транспонирования (от -24 до +24 полутонов для учета октав)
        var bestTranspose = baseTranspose
        var bestScore = Int.min

        for octaveShift in -2...4 {  // От -2 до +4 октав
            let totalTranspose = baseTranspose + octaveShift * 12
            
            // Проверяем что все ноты playable и в диапазоне
            var allPlayable = true
            var allInRange = true
            var playableCount = 0
            var inRangeCount = 0
            var avgPitch = 0
            
            for note in notes {
                let transposedPitch = UInt8(max(0, min(127, Int(note.pitch) + totalTranspose)))
                
                // Проверяем что нота playable (имеет аппликатуру)
                if WhistleConverter.pitchToFingering(transposedPitch, whistleKey: whistleKey) != nil {
                    playableCount += 1
                } else {
                    allPlayable = false
                }
                
                // Проверяем что нота в диапазоне
                if transposedPitch >= pitchRange.min && transposedPitch <= pitchRange.max {
                    inRangeCount += 1
                    avgPitch += Int(transposedPitch)
                } else {
                    allInRange = false
                }
            }
            
            // Если не все ноты playable или не все в диапазоне - пропускаем этот вариант
            if !allPlayable || !allInRange {
                continue
            }
            
            // Вычисляем средний pitch
            avgPitch = avgPitch / max(1, inRangeCount)
            
            // Вычисляем расстояние от тоники вистла
            let distanceFromTonic = abs(avgPitch - optimalTonicPitch)
            
            // Бонус за более высокие октавы (свистли - высокие инструменты)
            let heightBonus = max(0, octaveShift) * 50
            
            // Оценка: чем ближе к тонике вистла, тем лучше
            // Большой бонус за все ноты playable и в диапазоне
            let score = 10000 - distanceFromTonic + heightBonus

            if score > bestScore {
                bestScore = score
                bestTranspose = totalTranspose
            }
        }

        // Если не нашли подходящий вариант, возвращаем базовое транспонирование
        // (это не должно происходить, если тональность в списке playable keys)
        return bestTranspose
    }
    
    /// Транспонирует мелодию так, чтобы тоника была на 4 октаве (C4 = MIDI 60)
    /// Находит самую низкую ноту тоники в мелодии и транспонирует её в C4
    static func transposeToOctave4(key: String, notes: [MIDINote]) -> Int {
        // Получаем индекс тоники (0-11)
        let tonicIndex = noteNameToIndex(key)
        
        // Находим самую низкую ноту тоники в мелодии
        var lowestTonicPitch: Int? = nil
        
        for note in notes {
            let pitchClass = Int(note.pitch) % 12
            if pitchClass == tonicIndex {
                let pitch = Int(note.pitch)
                if lowestTonicPitch == nil || pitch < lowestTonicPitch! {
                    lowestTonicPitch = pitch
                }
            }
        }
        
        // Если не нашли тонику, используем самую низкую ноту
        if lowestTonicPitch == nil {
            lowestTonicPitch = notes.map { Int($0.pitch) }.min()
        }
        
        guard let tonicPitch = lowestTonicPitch else {
            return 0 // Если нет нот, не транспонируем
        }
        
        // Целевая тоника - C4 (60)
        let targetTonicPitch = 60
        
        // Вычисляем транспонирование
        let transpose = targetTonicPitch - tonicPitch
        
        // Ограничиваем транспонирование разумными пределами (-24 до +24 полутонов)
        return max(-24, min(24, transpose))
    }
}

