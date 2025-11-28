//
//  PianoRollView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 28.11.2025.
//

import SwiftUI

struct PianoRollView: View {
    let midiInfo: MIDIFileInfo
    let currentBeat: Double
    let startMeasure: Int
    let endMeasure: Int
    let isPlaying: Bool
    
    // Настройки отображения
    private let noteHeight: CGFloat = 8
    private let beatWidth: CGFloat = 40
    private let pianoKeyWidth: CGFloat = 50
    
    private var visibleNotes: [MIDINote] {
        let startBeat = Double(startMeasure - 1) * Double(midiInfo.beatsPerMeasure)
        let endBeat = Double(endMeasure) * Double(midiInfo.beatsPerMeasure)
        return midiInfo.allNotes.filter { note in
            note.endBeat > startBeat && note.startBeat < endBeat
        }
    }
    
    private var pitchRange: ClosedRange<UInt8> {
        // Расширяем диапазон на пару нот для лучшего вида
        let minP = max(0, Int(midiInfo.minPitch) - 2)
        let maxP = min(127, Int(midiInfo.maxPitch) + 2)
        return UInt8(minP)...UInt8(maxP)
    }
    
    private var totalRows: Int {
        Int(pitchRange.upperBound - pitchRange.lowerBound) + 1
    }
    
    private var visibleBeats: Double {
        Double((endMeasure - startMeasure + 1) * midiInfo.beatsPerMeasure)
    }
    
    private var startBeatOffset: Double {
        Double((startMeasure - 1) * midiInfo.beatsPerMeasure)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - pianoKeyWidth
            let calculatedBeatWidth = availableWidth / CGFloat(visibleBeats)
            let totalHeight = CGFloat(totalRows) * noteHeight
            
            HStack(spacing: 0) {
                // Piano keys на левой стороне
                PianoKeysView(
                    pitchRange: pitchRange,
                    noteHeight: noteHeight
                )
                .frame(width: pianoKeyWidth)
                
                // Основная область piano roll
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Фон с сеткой
                        GridBackground(
                            rows: totalRows,
                            beats: Int(visibleBeats),
                            noteHeight: noteHeight,
                            beatWidth: calculatedBeatWidth,
                            beatsPerMeasure: midiInfo.beatsPerMeasure,
                            pitchRange: pitchRange
                        )
                        
                        // Ноты
                        ForEach(visibleNotes) { note in
                            NoteView(
                                note: note,
                                pitchRange: pitchRange,
                                noteHeight: noteHeight,
                                beatWidth: calculatedBeatWidth,
                                startBeatOffset: startBeatOffset,
                                isActive: isNoteActive(note)
                            )
                        }
                        
                        // Курсор воспроизведения
                        if isPlaying || currentBeat > 0 {
                            let cursorX = CGFloat(currentBeat - startBeatOffset) * calculatedBeatWidth
                            if cursorX >= 0 && cursorX <= availableWidth {
                                Rectangle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 2, height: totalHeight)
                                    .offset(x: cursorX)
                            }
                        }
                    }
                    .frame(width: availableWidth, height: totalHeight)
                }
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func isNoteActive(_ note: MIDINote) -> Bool {
        currentBeat >= note.startBeat && currentBeat < note.endBeat
    }
}

// MARK: - Piano Keys

struct PianoKeysView: View {
    let pitchRange: ClosedRange<UInt8>
    let noteHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach((pitchRange).reversed(), id: \.self) { pitch in
                let isBlackKey = [1, 3, 6, 8, 10].contains(Int(pitch) % 12)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isBlackKey ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color(red: 0.15, green: 0.15, blue: 0.18))
                        .overlay(
                            Text(pitchToName(pitch))
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 4)
                            , alignment: .trailing
                        )
                }
                .frame(height: noteHeight)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 0.5)
                    , alignment: .bottom
                )
            }
        }
    }
    
    private func pitchToName(_ pitch: UInt8) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(pitch) / 12 - 1
        let note = Int(pitch) % 12
        // Показываем только ноты C для экономии места
        if note == 0 {
            return "C\(octave)"
        }
        return ""
    }
}

// MARK: - Grid Background

struct GridBackground: View {
    let rows: Int
    let beats: Int
    let noteHeight: CGFloat
    let beatWidth: CGFloat
    let beatsPerMeasure: Int
    let pitchRange: ClosedRange<UInt8>
    
    var body: some View {
        Canvas { context, size in
            // Горизонтальные линии (строки для каждой ноты)
            for row in 0...rows {
                let y = CGFloat(row) * noteHeight
                let pitch = Int(pitchRange.upperBound) - row
                let isBlackKey = [1, 3, 6, 8, 10].contains(pitch % 12)
                
                // Фон для чёрных клавиш
                if row < rows && isBlackKey {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: noteHeight)
                    context.fill(Path(rect), with: .color(Color.white.opacity(0.03)))
                }
                
                // Линия
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.white.opacity(0.1)), lineWidth: 0.5)
            }
            
            // Вертикальные линии (биты и такты)
            for beat in 0...beats {
                let x = CGFloat(beat) * beatWidth
                let isMeasureStart = beat % beatsPerMeasure == 0
                
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                
                if isMeasureStart {
                    context.stroke(path, with: .color(Color.white.opacity(0.3)), lineWidth: 1)
                } else {
                    context.stroke(path, with: .color(Color.white.opacity(0.1)), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Note View

struct NoteView: View {
    let note: MIDINote
    let pitchRange: ClosedRange<UInt8>
    let noteHeight: CGFloat
    let beatWidth: CGFloat
    let startBeatOffset: Double
    let isActive: Bool
    
    var body: some View {
        let row = Int(pitchRange.upperBound) - Int(note.pitch)
        let y = CGFloat(row) * noteHeight + 1
        let x = CGFloat(note.startBeat - startBeatOffset) * beatWidth
        let width = max(CGFloat(note.duration) * beatWidth - 2, 4)
        
        RoundedRectangle(cornerRadius: 2)
            .fill(noteColor)
            .frame(width: width, height: noteHeight - 2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(isActive ? 0.5 : 0.2), lineWidth: 0.5)
            )
            .shadow(color: noteColor.opacity(isActive ? 0.6 : 0), radius: 4)
            .offset(x: x, y: y)
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
    
    private var noteColor: Color {
        if isActive {
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Оранжевый для активной
        }
        
        // Цвет по каналу или высоте
        let hue = Double(note.pitch % 12) / 12.0
        return Color(hue: hue * 0.3 + 0.55, saturation: 0.7, brightness: 0.8) // Фиолетово-голубая гамма
    }
}

// MARK: - Measure Selector

struct MeasureSelectorView: View {
    @Binding var startMeasure: Int
    @Binding var endMeasure: Int
    let totalMeasures: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Measures")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 20) {
                // Start measure
                VStack(spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if startMeasure > 1 {
                                startMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.purple.opacity(0.8))
                        }
                        
                        Text("\(startMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button(action: {
                            if startMeasure < endMeasure {
                                startMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple.opacity(0.8))
                        }
                    }
                }
                
                Text("—")
                    .foregroundColor(.gray)
                
                // End measure
                VStack(spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if endMeasure > startMeasure {
                                endMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                        
                        Text("\(endMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button(action: {
                            if endMeasure < totalMeasures {
                                endMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                    }
                }
            }
            
            // Quick selection buttons
            HStack(spacing: 10) {
                QuickSelectButton(title: "All") {
                    startMeasure = 1
                    endMeasure = totalMeasures
                }
                
                QuickSelectButton(title: "1-4") {
                    startMeasure = 1
                    endMeasure = min(4, totalMeasures)
                }
                
                QuickSelectButton(title: "5-8") {
                    if totalMeasures >= 5 {
                        startMeasure = 5
                        endMeasure = min(8, totalMeasures)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct QuickSelectButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
}

#Preview {
    if let url = Bundle.main.url(forResource: "silverspear", withExtension: "mid"),
       let info = MIDIParser.parse(url: url) {
        PianoRollView(
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

