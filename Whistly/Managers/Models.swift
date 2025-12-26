import SwiftUI

enum ViewMode: String, CaseIterable {
    case fingerChart = "Fingering"
    case pianoRoll = "Piano Roll"
    
    var icon: String {
        switch self {
        case .pianoRoll: return "pianokeys"
        case .fingerChart: return "hand.raised.fingers.spread"
        }
    }
}

enum TuneType: String, CaseIterable, Codable {
    case unknown = "tune"
    case reel = "reel"
    case jig = "jig"
    case slip = "slip jig"
    case hornpipe = "hornpipe"
    case polka = "polka"
    case slide = "slide"
    case walz = "walz"
    case barndance = "barndance"
    case strathspey = "strathspey"
    case threeTwo = "three-two"
    case mazurka = "mazurka"
    case march = "march"
    
}

enum WhistleKey: String, CaseIterable, Codable {
    case Eb = "Eb"
    case D = "D"
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
    
    var displayName: String {
        switch self {
        case .Eb: return "E♭"
        case .D: return "D"
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
    
    var tonicNote: Int {
        switch self {
        case .Eb:      return 3
        case .D:       return 2
        case .Csharp:  return 1
        case .C:       return 0
        case .B:       return 11
        case .Bb:      return 10
        case .A:       return 9
        case .Ab:      return 8
        case .G:       return 7
        case .Fsharp:  return 6
        case .F:       return 5
        case .E:       return 4
        }
    }

    var pitchRange: (min: UInt8, max: UInt8) {
        switch self {
        case .Eb:      return (63, 84)
        case .D:       return (62, 83)
        case .Csharp:  return (61, 82)
        case .C:       return (60, 81)
        case .B:       return (59, 80)
        case .Bb:      return (58, 79)
        case .A:       return (57, 78)
        case .Ab:      return (56, 77)
        case .G:       return (55, 76)
        case .Fsharp:  return (54, 75)
        case .F:       return (53, 74)
        case .E:       return (52, 73)
        }
    }
    
    func getNotes() -> [UInt8] {
        let tonicNote = self.tonicNote
        let pitchRange = self.pitchRange
        let minPitch = Int(pitchRange.min)
        let maxPitch = Int(pitchRange.max)
        
        let intervals = [0, 2, 4, 5, 7, 9, 10, 11]
        
        let tonicOctave = (minPitch - tonicNote) / 12 + 1
        let upperOctaveThreshold = tonicNote + 12 * tonicOctave
        
        let minOctave = minPitch / 12
        let maxOctave = maxPitch / 12
        
        var notes = Set<UInt8>()
        
        for interval in intervals {
            let noteInOctave = (tonicNote + interval) % 12
            
            for octave in minOctave...maxOctave {
                let pitch = noteInOctave + octave * 12
                
                if pitch >= minPitch && pitch <= maxPitch {
                    notes.insert(UInt8(pitch))
                }
            }
        }
        
        return Array(notes).sorted()
    }
    
    func from(tuneKey: String) -> WhistleKey {
        let key = tuneKey.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !key.isEmpty else { return .D }
        
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
        case "D": return .D
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
        default: return .D
        }
    }
}

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
/// Структура для хранения информации о playable варианте тональности
// struct PlayableKeyVariant {
//    let key: String           // Название тональности
//    let melodyMin: UInt8      // Минимальная нота мелодии
//    let transpose: Int        // Транспонирование
//}

// MARK: - Pitch to Degree Converter
struct PlayableKey: Hashable {
    let keyName: String
    let transpose: Int
    let rootNote: UInt8
}
class WhistleConverter {
    
    /// Преобразует MIDI pitch в аппликатуру на выбранном вистле
    /// Возвращает nil если нота не может быть сыграна на данном вистле (хроматическая нота)
    func pitchToFingering(_ pitch: UInt8, whistleKey: WhistleKey) -> WhistleScaleDegree? {
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
        case 10: return .flatVII  // ♭VII - всегда одинаково
        case 11: return .VII      // VII - всегда одинаково
        default: return nil  // Хроматические ноты
        }
    }
    
    func pitchToNoteName(_ pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        return "\(noteNames[note])\(octave)"
    }

    

    func keyFinder(for whistle: WhistleKey, tune: [MIDINote]) -> [(Int, [MIDINote])] {
        var result: [(Int, [MIDINote])] = []
        print("Поиск возможных тональностей")
        let whistleUniqueNotes = Set(whistle.getNotes().map { Int($0).getNoteName().dropLast() }).sorted()
                print("Звукоряд Вистла \(whistle): \(whistleUniqueNotes)")
        for i in 0...11 {
            let tuneUniqueNotes = Set(tune.map { (Int($0.pitch) + i).getNoteName().dropLast() }).sorted()
            var tuneNotesArray = tuneUniqueNotes
            var scale: [String] = []
            while !tuneNotesArray.isEmpty {
                if let note = tuneNotesArray.popLast() {
                    if !whistleUniqueNotes.contains(where: { $0 == note }) {
                         break
                    } else {
                        scale.append(String(note))
                    }
                }
            }
            if scale.count == tuneUniqueNotes.count {
                let transposedNotes = tune.map { note in
                    MIDINote(
                        pitch: UInt8(Int(note.pitch) + i),
                        velocity: note.velocity,
                        startBeat: note.startBeat,
                        duration: note.duration,
                        channel: note.channel
                    )
                }
                result.append((i, transposedNotes))
                print("Звукоряд мелодии +\(i) подошел: \(scale)")
            }
        }
//        let keys = result.map { KeyDetector.detectKey(from: $0) }
        return result
    }
    
    func rangeFinder(for whistle: WhistleKey, tunes: [(Int, [MIDINote])]) -> [PlayableKey] {
        var result: [PlayableKey] = []
        let pitchRange = whistle.pitchRange
        
        for tune in tunes {
            guard let minPitch = tune.1.map({ $0.pitch }).min(),
                  let maxPitch = tune.1.map({ $0.pitch }).max(),
                  let root = tune.1.first?.pitch else {
                continue
            }
            
            let keyName = KeyDetector.detectKey(from: tune.1)
            
            for octaveShift in -2...2 {
                let shiftedMin = Int(minPitch) + octaveShift * 12
                let shiftedMax = Int(maxPitch) + octaveShift * 12
                let shiftedRoot = Int(root) + octaveShift * 12
                
                if shiftedMin >= Int(pitchRange.min) && 
                   shiftedMax <= Int(pitchRange.max) && 
                   shiftedRoot >= 0 && 
                   shiftedRoot <= 127 {
                    let playableKey = PlayableKey(
                        keyName: keyName,
                        transpose: tune.0,
                        rootNote: UInt8(shiftedRoot)
                    )
                    result.append(playableKey)
                    print("  ✅ Добавлен вариант: \(keyName), transpose: \(tune.0), rootNote: \(shiftedRoot), диапазон: \(shiftedMin)-\(shiftedMax)")
                } else {
//                    print("  ❌ Пропущен: \(keyName), transpose: \(tune.0), octaveShift: \(octaveShift), диапазон: \(shiftedMin)-\(shiftedMax), требуется: \(pitchRange.min)-\(pitchRange.max)")
                }
            }
        }
        
        print("Варианты тональностей мелодии для вистла \(whistle) - \(result.map { $0.keyName })")
        return result
    }
}

