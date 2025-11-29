//
//  FingerChartView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import SwiftUI

// MARK: - Whistle Scale Degree

/// Ступень вистла
enum WhistleScaleDegree: String, CaseIterable {
    case I = "I"
    case II = "II"
    case III = "III"
    case IV = "IV"
    case V = "V"
    case VI = "VI"
    case flatVII = "♭VII"
    case VII = "VII"
    // Октавные варианты
    case I2 = "I²"
    case II2 = "II²"
    case III2 = "III²"
    case IV2 = "IV²"
    case V2 = "V²"
    case VI2 = "VI²"
    case VII2 = "VII²"
    
    /// Имя файла изображения аппликатуры
    var imageName: String {
        return rawValue
    }
}

// MARK: - Pitch to Degree Converter

struct WhistleConverter {
    /// Базовая тоника вистла D (MIDI 62 = D4, или 74 = D5 для low whistle)
    /// Для стандартного вистла D: низкая нота D5 = MIDI 74
    static let baseTonic: Int = 74  // D5
    
    /// Интервалы мажорной гаммы от тоники (в полутонах)
    /// D=0, E=2, F#=4, G=5, A=7, B=9, C#=11, D'=12
    private static let majorScaleIntervals = [0, 2, 4, 5, 7, 9, 11, 12]
    
    /// Конвертирует MIDI pitch в ступень вистла
    /// - Parameter pitch: MIDI номер ноты (0-127)
    /// - Returns: Ступень вистла или nil если нота вне диапазона
    static func pitchToDegree(_ pitch: UInt8) -> WhistleScaleDegree? {
        let midiPitch = Int(pitch)
        
        // Вычисляем интервал от тоники (с учётом октав)
        let interval = midiPitch - baseTonic
        
        // Нормализуем интервал в пределах октавы
        let normalizedInterval = ((interval % 12) + 12) % 12
        
        // Определяем октаву (0 = нижняя, 1 = верхняя)
        let octave = interval >= 12 ? 1 : 0
        
        // Определяем ступень по интервалу
        switch normalizedInterval {
        case 0:  // D
            return octave == 0 ? .I : .I2
        case 2:  // E
            return octave == 0 ? .II : .II2
        case 4:  // F#
            return octave == 0 ? .III : .III2
        case 5:  // G
            return octave == 0 ? .IV : .IV2
        case 7:  // A
            return octave == 0 ? .V : .V2
        case 9:  // B
            return octave == 0 ? .VI : .VI2
        case 10: // C (♭VII)
            return .flatVII
        case 11: // C#
            return octave == 0 ? .VII : .VII2
        default:
            // Хроматические ноты - пытаемся найти ближайшую
            return findClosestDegree(normalizedInterval: normalizedInterval, octave: octave)
        }
    }
    
    /// Находит ближайшую ступень для хроматических нот
    private static func findClosestDegree(normalizedInterval: Int, octave: Int) -> WhistleScaleDegree? {
        // Для промежуточных нот выбираем ближайшую диатоническую
        switch normalizedInterval {
        case 1:  // D# → E (II)
            return octave == 0 ? .II : .II2
        case 3:  // Eb/E# → E или F#
            return octave == 0 ? .III : .III2
        case 6:  // G# → A (V)
            return octave == 0 ? .V : .V2
        case 8:  // G#/Ab → A
            return octave == 0 ? .V : .V2
        default:
            return nil
        }
    }
    
    /// Возвращает название ноты для отображения
    static func pitchToNoteName(_ pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        return "\(noteNames[note])\(octave)"
    }
}

// MARK: - Finger Chart View

struct FingerChartView: View {
    let midiInfo: MIDIFileInfo
    let currentBeat: Double
    let startMeasure: Int
    let endMeasure: Int
    let isPlaying: Bool
    
    // Настройки отображения
    private let fingerChartWidth: CGFloat = 60
    private let fingerChartSpacing: CGFloat = 8
    
    /// Видимые ноты в выбранном диапазоне
    private var visibleNotes: [MIDINote] {
        let startBeat = Double(startMeasure - 1) * Double(midiInfo.beatsPerMeasure)
        let endBeat = Double(endMeasure) * Double(midiInfo.beatsPerMeasure)
        return midiInfo.allNotes.filter { note in
            note.endBeat > startBeat && note.startBeat < endBeat
        }
    }
    
    /// Начало в битах
    private var startBeatOffset: Double {
        Double((startMeasure - 1) * midiInfo.beatsPerMeasure)
    }
    
    /// Индекс текущей активной ноты
    private var activeNoteIndex: Int? {
        visibleNotes.firstIndex { note in
            currentBeat >= note.startBeat && currentBeat < note.endBeat
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Текущая активная нота (большая)
                CurrentFingerChartView(
                    note: activeNote,
                    geometry: geometry
                )
                
                // Лента нот снизу
                NoteStripView(
                    notes: visibleNotes,
                    activeNoteIndex: activeNoteIndex,
                    fingerChartWidth: fingerChartWidth,
                    geometry: geometry
                )
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var activeNote: MIDINote? {
        if let index = activeNoteIndex {
            return visibleNotes[index]
        }
        return visibleNotes.first
    }
}

// MARK: - Current Finger Chart (большая аппликатура)

struct CurrentFingerChartView: View {
    let note: MIDINote?
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 8) {
            if let note = note,
               let degree = WhistleConverter.pitchToDegree(note.pitch) {
                
                // Аппликатура
                Image(degree.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: geometry.size.height * 0.6)
                    .shadow(color: .cyan.opacity(0.3), radius: 10)
                
                // Название ступени и ноты
                HStack(spacing: 16) {
                    Text(degree.rawValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(WhistleConverter.pitchToNoteName(note.pitch))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
            } else {
                // Пустое состояние
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Нет ноты")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .frame(maxHeight: geometry.size.height * 0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

// MARK: - Note Strip (лента нот снизу)

struct NoteStripView: View {
    let notes: [MIDINote]
    let activeNoteIndex: Int?
    let fingerChartWidth: CGFloat
    let geometry: GeometryProxy
    
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                        SmallFingerChartView(
                            note: note,
                            isActive: index == activeNoteIndex,
                            isPast: activeNoteIndex != nil && index < activeNoteIndex!
                        )
                        .frame(width: fingerChartWidth)
                        .id(index)
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 80)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onChange(of: activeNoteIndex) { _, newIndex in
                if let index = newIndex {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Small Finger Chart (маленькая аппликатура в ленте)

struct SmallFingerChartView: View {
    let note: MIDINote
    let isActive: Bool
    let isPast: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            if let degree = WhistleConverter.pitchToDegree(note.pitch) {
                Image(degree.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .opacity(isPast ? 0.4 : 1.0)
                
                Text(degree.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isActive ? .cyan : (isPast ? .gray.opacity(0.5) : .white.opacity(0.7)))
            } else {
                // Неизвестная нота
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 50)
                    .overlay(
                        Text("?")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
                
                Text(WhistleConverter.pitchToNoteName(note.pitch))
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.cyan.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    if let url = Bundle.main.url(forResource: "silverspear", withExtension: "mid"),
       let info = MIDIParser.parse(url: url) {
        FingerChartView(
            midiInfo: info,
            currentBeat: 4,
            startMeasure: 1,
            endMeasure: 8,
            isPlaying: false
        )
        .frame(height: 300)
        .padding()
        .background(Color.black)
    }
}

