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
    
    // Состояние зума
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    
    // Настройки отображения
    private let noteHeight: CGFloat = 8
    private let baseBeatWidth: CGFloat = 40
    private let pianoKeyWidth: CGFloat = 50
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 4.0
    
    private var visibleNotes: [MIDINote] {
        let startBeat = Double(startMeasure - 1) * Double(midiInfo.beatsPerMeasure)
        let endBeat = Double(endMeasure) * Double(midiInfo.beatsPerMeasure)
        return midiInfo.allNotes.filter { note in
            note.endBeat > startBeat && note.startBeat < endBeat
        }
    }
    
    private var pitchRange: ClosedRange<UInt8> {
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
            let baseWidth = availableWidth / CGFloat(visibleBeats)
            let scaledBeatWidth = baseWidth * scale
            let totalContentWidth = CGFloat(visibleBeats) * scaledBeatWidth
            let totalHeight = CGFloat(totalRows) * noteHeight
            
            // Ограничиваем offset чтобы не выйти за пределы
            let maxOffset = max(0, totalContentWidth - availableWidth)
            
            HStack(spacing: 0) {
                // Piano keys на левой стороне
                PianoKeysView(
                    pitchRange: pitchRange,
                    noteHeight: noteHeight
                )
                .frame(width: pianoKeyWidth)
                
                // Основная область piano roll с зумом
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Фон с сеткой
                        GridBackground(
                            rows: totalRows,
                            beats: Int(visibleBeats),
                            noteHeight: noteHeight,
                            beatWidth: scaledBeatWidth,
                            beatsPerMeasure: midiInfo.beatsPerMeasure,
                            pitchRange: pitchRange
                        )
                        
                        // Ноты
                        ForEach(visibleNotes) { note in
                            NoteView(
                                note: note,
                                pitchRange: pitchRange,
                                noteHeight: noteHeight,
                                beatWidth: scaledBeatWidth,
                                startBeatOffset: startBeatOffset,
                                isActive: isNoteActive(note)
                            )
                        }
                        
                        // Курсор воспроизведения
                        if isPlaying || currentBeat > 0 {
                            let cursorX = CGFloat(currentBeat - startBeatOffset) * scaledBeatWidth
                            Rectangle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 2, height: totalHeight)
                                .offset(x: cursorX)
                        }
                    }
                    .frame(width: totalContentWidth, height: totalHeight)
                    .offset(x: -min(max(0, offset), maxOffset))
                }
                .clipped()
                .gesture(
                    // Pinch to zoom
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = min(max(newScale, minScale), maxScale)
                            
                            // Корректируем offset при зуме чтобы центр оставался на месте
                            let newMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
                            offset = min(offset, newMaxOffset)
                        }
                        .onEnded { _ in
                            lastScale = scale
                            lastOffset = offset
                        }
                )
                .simultaneousGesture(
                    // Drag to pan (когда зум > 1)
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                let newOffset = lastOffset - value.translation.width
                                let currentMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
                                offset = min(max(0, newOffset), currentMaxOffset)
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .overlay(
                    // Индикатор зума
                    VStack {
                        HStack {
                            Spacer()
                            if scale != 1.0 {
                                Text("\(Int(scale * 100))%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.5))
                                    )
                                    .padding(6)
                            }
                        }
                        Spacer()
                    }
                )
                .onTapGesture(count: 2) {
                    // Double tap to reset zoom
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = 1.0
                        lastScale = 1.0
                        offset = 0
                        lastOffset = 0
                    }
                }
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: startMeasure) { _, _ in resetZoom() }
        .onChange(of: endMeasure) { _, _ in resetZoom() }
    }
    
    private func isNoteActive(_ note: MIDINote) -> Bool {
        currentBeat >= note.startBeat && currentBeat < note.endBeat
    }
    
    private func resetZoom() {
        scale = 1.0
        lastScale = 1.0
        offset = 0
        lastOffset = 0
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

