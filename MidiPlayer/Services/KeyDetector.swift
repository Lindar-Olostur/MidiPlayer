//
//  KeyDetector.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import Foundation

// MARK: - Key Detector

/// Анализатор тональности по нотам (алгоритм Крумхансла-Шмуклера)
struct KeyDetector {
    
    /// Профили мажорных тональностей (Krumhansl-Kessler)
    /// Показывают "вес" каждой ступени в мажорной гамме
    private static let majorProfile: [Double] = [
        6.35,  // C  (I)
        2.23,  // C#
        3.48,  // D  (II)
        2.33,  // D#
        4.38,  // E  (III)
        4.09,  // F  (IV)
        2.52,  // F#
        5.19,  // G  (V)
        2.39,  // G#
        3.66,  // A  (VI)
        2.29,  // A#
        2.88   // B  (VII)
    ]
    
    /// Профили минорных тональностей
    private static let minorProfile: [Double] = [
        6.33,  // C  (I)
        2.68,  // C#
        3.52,  // D  (II)
        5.38,  // D# (♭III)
        2.60,  // E
        3.53,  // F  (IV)
        2.54,  // F#
        4.75,  // G  (V)
        3.98,  // G# (♭VI)
        2.69,  // A
        3.34,  // A# (♭VII)
        3.17   // B
    ]
    
    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    /// Определяет тональность по массиву нот
    /// Возвращает строку вида "D", "Am", "G" и т.д.
    static func detectKey(from notes: [MIDINote]) -> String {
        guard !notes.isEmpty else { return "C" }
        
        // Подсчитываем частоту каждого pitch class (0-11) с весами
        var pitchClassCounts = [Double](repeating: 0, count: 12)
        
        // Сортируем по времени для анализа позиций
        let sortedNotes = notes.sorted { $0.startBeat < $1.startBeat }
        
        for (index, note) in sortedNotes.enumerated() {
            let pitchClass = Int(note.pitch) % 12
            var weight = note.duration
            
            // Увеличиваем вес для более длинных нот (часто тоника)
            weight *= (1.0 + note.duration * 0.5)
            
            // Увеличиваем вес для более громких нот (акценты)
            weight *= (1.0 + Double(note.velocity) / 127.0 * 0.3)
            
            // Первая нота часто тоника
            if index == 0 {
                weight *= 2.0
            }
            
            // Последняя нота часто тоника
            if index == sortedNotes.count - 1 {
                weight *= 2.0
            }
            
            // Ноты в конце фраз (каденции) - последние 10% нот
            let phraseEndThreshold = Double(sortedNotes.count) * 0.9
            if Double(index) >= phraseEndThreshold {
                weight *= 1.5
            }
            
            pitchClassCounts[pitchClass] += weight
        }
        
        // Нормализуем
        let total = pitchClassCounts.reduce(0, +)
        if total > 0 {
            pitchClassCounts = pitchClassCounts.map { $0 / total }
        }
        
        var bestKey = "C"
        var bestCorrelation = -Double.infinity
        var isMinor = false
        var majorScores: [Double] = []
        var minorScores: [Double] = []
        
        // Проверяем все 12 мажорных и 12 минорных тональностей
        for root in 0..<12 {
            let majorCorr = correlation(pitchClassCounts, shiftedProfile(majorProfile, by: root))
            let minorCorr = correlation(pitchClassCounts, shiftedProfile(minorProfile, by: root))
            
            majorScores.append(majorCorr)
            minorScores.append(minorCorr)
            
            // Бонус если тоника (root) встречается часто
            let tonicBonus = pitchClassCounts[root] * 0.3
            let adjustedMajor = majorCorr + tonicBonus
            let adjustedMinor = minorCorr + tonicBonus
            
            if adjustedMajor > bestCorrelation {
                bestCorrelation = adjustedMajor
                bestKey = noteNames[root]
                isMinor = false
            }
            
            if adjustedMinor > bestCorrelation {
                bestCorrelation = adjustedMinor
                bestKey = noteNames[root]
                isMinor = true
            }
        }
        
        // Если мажор и минор очень близки (разница < 0.05), предпочитаем мажор
        if isMinor {
            let majorMax = majorScores.max() ?? 0
            let minorMax = minorScores.max() ?? 0
            if abs(majorMax - minorMax) < 0.05 && majorMax > 0 {
                // Ищем лучший мажор
                if let bestMajorIndex = majorScores.firstIndex(of: majorMax) {
                    bestKey = noteNames[bestMajorIndex]
                    isMinor = false
                }
            }
        }
        
        return isMinor ? "\(bestKey)m" : bestKey
    }
    
    /// Сдвигает профиль на заданное количество полутонов
    private static func shiftedProfile(_ profile: [Double], by semitones: Int) -> [Double] {
        var shifted = [Double](repeating: 0, count: 12)
        for i in 0..<12 {
            let newIndex = (i + semitones) % 12
            shifted[newIndex] = profile[i]
        }
        return shifted
    }
    
    /// Вычисляет корреляцию Пирсона между двумя массивами
    private static func correlation(_ a: [Double], _ b: [Double]) -> Double {
        let n = Double(a.count)
        let sumA = a.reduce(0, +)
        let sumB = b.reduce(0, +)
        let sumAB = zip(a, b).map(*).reduce(0, +)
        let sumA2 = a.map { $0 * $0 }.reduce(0, +)
        let sumB2 = b.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumAB - sumA * sumB
        let denominator = sqrt((n * sumA2 - sumA * sumA) * (n * sumB2 - sumB * sumB))
        
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
}

