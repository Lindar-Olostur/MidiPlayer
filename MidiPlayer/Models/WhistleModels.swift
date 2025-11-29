//
//  WhistleModels.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import Foundation

// MARK: - Whistle Key (строй вистла)

/// Строй вистла от высокого Eb до Low D (хроматически)
enum WhistleKey: String, CaseIterable {
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
    case Eb_low = "Low Eb"
    case D_low = "Low D"
    
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
        case .Eb_low: return "Low E♭"
        case .D_low: return "Low D"
        }
    }
    
    /// Номер ноты тоники (0-11, где C=0, D=2, и т.д.)
    var tonicNote: Int {
        switch self {
        case .Eb, .Eb_low:    return 3   // Eb
        case .D_high, .D_low: return 2   // D
        case .Csharp:         return 1   // C#
        case .C:              return 0   // C
        case .B:              return 11  // B
        case .Bb:             return 10  // Bb
        case .A:              return 9   // A
        case .Ab:             return 8   // Ab
        case .G:              return 7   // G
        case .Fsharp:         return 6   // F#
        case .F:              return 5   // F
        case .E:              return 4   // E
        }
    }
}

// MARK: - Whistle Scale Degree (только первая октава)

enum WhistleScaleDegree: String, CaseIterable {
    case I = "I"
    case II = "II"
    case III = "III"
    case IV = "IV"
    case V = "V"
    case VI = "VI"
    case flatVII = "♭VII"
    case VII = "VII"
    
    var imageName: String { rawValue }
}

// MARK: - Fingering Info (аппликатура + признак передува)

struct FingeringInfo {
    let degree: WhistleScaleDegree  // Базовая ступень (всегда первой октавы)
    let needsOverblow: Bool          // Нужен передув (вторая октава)
}

// MARK: - Pitch to Degree Converter

struct WhistleConverter {
    
    /// Преобразует MIDI pitch в аппликатуру на выбранном вистле
    /// Возвращает nil если нота не может быть сыграна на данном вистле (хроматическая нота)
    static func pitchToFingering(_ pitch: UInt8, whistleKey: WhistleKey) -> FingeringInfo? {
        let midiPitch = Int(pitch)
        let pitchNote = midiPitch % 12  // Нота без октавы (0-11)
        let whistleTonicNote = whistleKey.tonicNote
        
        // Вычисляем интервал от тоники вистла (0-11)
        var interval = pitchNote - whistleTonicNote
        if interval < 0 {
            interval += 12
        }
        
        // Определяем октаву: от C5 (72) и выше - верхняя октава (нужен передув)
        let needsOverblow = midiPitch >= 72
        
        // Только диатонические ступени мажорной гаммы
        let degree: WhistleScaleDegree?
        switch interval {
        case 0:  degree = .I
        case 2:  degree = .II
        case 4:  degree = .III
        case 5:  degree = .IV
        case 7:  degree = .V
        case 9:  degree = .VI
        case 10: degree = .flatVII
        case 11: degree = .VII
        default: degree = nil  // Хроматические ноты
        }
        
        guard let deg = degree else { return nil }
        return FingeringInfo(degree: deg, needsOverblow: needsOverblow)
    }
    
    static func pitchToNoteName(_ pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        return "\(noteNames[note])\(octave)"
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

