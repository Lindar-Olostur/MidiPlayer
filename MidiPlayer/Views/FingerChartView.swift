//
//  FingerChartView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import SwiftUI

// MARK: - Finger Chart View

struct FingerChartView: View {
    let midiInfo: MIDIFileInfo
    let currentBeat: Double
    let startMeasure: Int
    let endMeasure: Int
    let isPlaying: Bool
    let whistleKey: WhistleKey
    
    // Настройки
    private let noteHeight: CGFloat = 6
    private let pianoKeyWidth: CGFloat = 35
    private let fingeringRowHeight: CGFloat = 70
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    
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
            let pianoRollHeight = CGFloat(totalRows) * noteHeight
            let maxOffset = max(0, totalContentWidth - availableWidth)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Метка для ряда аппликатур
                    Text("🎵")
                        .font(.system(size: 14))
                        .frame(width: pianoKeyWidth, height: fingeringRowHeight)
                        .background(Color.white)
                    
                    // Ряд аппликатур (синхронно скроллится с пианороллом)
                    FingeringRowView(
                        notes: visibleNotes,
                        currentBeat: currentBeat,
                        startBeatOffset: startBeatOffset,
                        beatWidth: scaledBeatWidth,
                        rowHeight: fingeringRowHeight,
                        totalWidth: totalContentWidth,
                        offset: min(max(0, offset), maxOffset),
                        isPlaying: isPlaying,
                        whistleKey: whistleKey
                    )
                    .frame(height: fingeringRowHeight)
                    .clipped()
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                
                // Разделитель
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    // Piano keys
                    PianoKeysCompactView(
                        pitchRange: pitchRange,
                        noteHeight: noteHeight
                    )
                    .frame(width: pianoKeyWidth)
                    
                    // Piano roll
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            // Сетка
                            GridBackgroundCompact(
                                rows: totalRows,
                                beats: Int(visibleBeats),
                                noteHeight: noteHeight,
                                beatWidth: scaledBeatWidth,
                                beatsPerMeasure: midiInfo.beatsPerMeasure,
                                pitchRange: pitchRange
                            )
                            
                            // Ноты
                            ForEach(visibleNotes) { note in
                                NoteViewCompact(
                                    note: note,
                                    pitchRange: pitchRange,
                                    noteHeight: noteHeight,
                                    beatWidth: scaledBeatWidth,
                                    startBeatOffset: startBeatOffset,
                                    isActive: isNoteActive(note)
                                )
                            }
                            
                            // Курсор воспроизведения
                            if isPlaying || currentBeat > startBeatOffset {
                                let cursorX = CGFloat(currentBeat - startBeatOffset) * scaledBeatWidth
                                Rectangle()
                                    .fill(Color.red.opacity(0.9))
                                    .frame(width: 2, height: pianoRollHeight)
                                    .offset(x: cursorX)
                                    .shadow(color: .red.opacity(0.5), radius: 3)
                            }
                        }
                        .frame(width: totalContentWidth, height: pianoRollHeight)
                        .offset(x: -min(max(0, offset), maxOffset))
                    }
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, minScale), maxScale)
                                let newMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
                                offset = min(offset, newMaxOffset)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                lastOffset = offset
                            }
                    )
                    .simultaneousGesture(
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
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = 0
                            lastOffset = 0
                        }
                    }
                }
            }
            // Индикатор зума
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if scale != 1.0 {
                            Text("\(Int(scale * 100))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                                .padding(6)
                        }
                    }
                    Spacer()
                }
            )
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

// MARK: - Fingering Row View

struct FingeringRowView: View {
    let notes: [MIDINote]
    let currentBeat: Double
    let startBeatOffset: Double
    let beatWidth: CGFloat
    let rowHeight: CGFloat
    let totalWidth: CGFloat
    let offset: CGFloat
    let isPlaying: Bool
    let whistleKey: WhistleKey
    
    private let symbolRowHeight: CGFloat = 20  // Высота ряда с плюсиками и курсором
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхний ряд: аппликатуры
            ZStack(alignment: .topLeading) {
                Color.white
                
                ForEach(notes) { note in
                    let x = CGFloat(note.startBeat - startBeatOffset) * beatWidth
                    let width = max(CGFloat(note.duration) * beatWidth, 40)
                    
                    FingeringImageView(
                        note: note,
                        width: width,
                        whistleKey: whistleKey
                    )
                    .frame(width: width, height: rowHeight - symbolRowHeight - 8)
                    .offset(x: x, y: 4)
                }
            }
            .frame(width: totalWidth, height: rowHeight - symbolRowHeight)
            
            // Нижний ряд: индикаторы активности и плюсики
            ZStack(alignment: .topLeading) {
                Color(white: 1)
                
                ForEach(notes) { note in
                    let x = CGFloat(note.startBeat - startBeatOffset) * beatWidth
                    let isActive = currentBeat >= note.startBeat && currentBeat < note.endBeat
                    
                    // Индикатор активности - плавное свечение TODO
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(Color.orange)
//                        .frame(width: 20, height: 4)
//                        .shadow(color: Color.orange.opacity(isActive ? 0.6 : 0), radius: 4, y: 0)
//                        .offset(x: x - 6, y: symbolRowHeight - 6)
//                        .opacity(isActive ? 1 : 0)
//                        .animation(.easeInOut(duration: 0.2), value: isActive)
//                    
                    // Плюсик для передува (кроме VII и ♭VII)
                    if let fingering = WhistleConverter.pitchToFingering(note.pitch, whistleKey: whistleKey),
                       fingering.needsOverblow,
                       fingering.degree != .VII && fingering.degree != .flatVII {
                        Text("+")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                            .offset(x: x - 1, y: -4)
                    }
                }
            }
            .frame(width: totalWidth, height: symbolRowHeight)
        }
        .offset(x: -offset)
    }
}

// MARK: - Fingering Image View

struct FingeringImageView: View {
    let note: MIDINote
    let width: CGFloat
    let whistleKey: WhistleKey
    
    var body: some View {
        if let fingering = WhistleConverter.pitchToFingering(note.pitch, whistleKey: whistleKey) {
            // Используем картинку первой октавы для всех нот
            Image(fingering.degree.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Неизвестная нота (хроматическая)
            VStack(spacing: 1) {
                Text("?")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                Text(WhistleConverter.pitchToNoteName(note.pitch))
                    .font(.system(size: 7))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Compact Piano Keys

struct PianoKeysCompactView: View {
    let pitchRange: ClosedRange<UInt8>
    let noteHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach((pitchRange).reversed(), id: \.self) { pitch in
                let isBlackKey = [1, 3, 6, 8, 10].contains(Int(pitch) % 12)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(isBlackKey ? Color(white: 0.18) : Color(white: 0.14))
                        .overlay(
                            Text(pitchToName(pitch))
                                .font(.system(size: 6, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 3)
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
        let note = Int(pitch) % 12
        if note == 0 {
            let octave = Int(pitch) / 12 - 1
            return "C\(octave)"
        }
        return ""
    }
}

// MARK: - Compact Grid Background

struct GridBackgroundCompact: View {
    let rows: Int
    let beats: Int
    let noteHeight: CGFloat
    let beatWidth: CGFloat
    let beatsPerMeasure: Int
    let pitchRange: ClosedRange<UInt8>
    
    var body: some View {
        Canvas { context, size in
            for row in 0...rows {
                let y = CGFloat(row) * noteHeight
                let pitch = Int(pitchRange.upperBound) - row
                let isBlackKey = [1, 3, 6, 8, 10].contains(pitch % 12)
                
                if row < rows && isBlackKey {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: noteHeight)
                    context.fill(Path(rect), with: .color(Color.white.opacity(0.02)))
                }
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5)
            }
            
            for beat in 0...beats {
                let x = CGFloat(beat) * beatWidth
                let isMeasureStart = beat % beatsPerMeasure == 0
                
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                
                if isMeasureStart {
                    context.stroke(path, with: .color(Color.white.opacity(0.25)), lineWidth: 1)
                } else {
                    context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Compact Note View

struct NoteViewCompact: View {
    let note: MIDINote
    let pitchRange: ClosedRange<UInt8>
    let noteHeight: CGFloat
    let beatWidth: CGFloat
    let startBeatOffset: Double
    let isActive: Bool
    
    var body: some View {
        let row = Int(pitchRange.upperBound) - Int(note.pitch)
        let y = CGFloat(row) * noteHeight + 0.5
        let x = CGFloat(note.startBeat - startBeatOffset) * beatWidth
        let width = max(CGFloat(note.duration) * beatWidth - 1, 3)
        
        RoundedRectangle(cornerRadius: 1.5)
            .fill(noteColor)
            .frame(width: width, height: noteHeight - 1)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(Color.white.opacity(isActive ? 0.4 : 0.15), lineWidth: 0.5)
            )
            .shadow(color: noteColor.opacity(isActive ? 0.6 : 0), radius: 3)
            .offset(x: x, y: y)
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
    
    private var noteColor: Color {
        if isActive {
            return Color.orange
        }
        let hue = Double(note.pitch % 12) / 12.0
        return Color(hue: hue * 0.3 + 0.55, saturation: 0.7, brightness: 0.75)
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
            isPlaying: true,
            whistleKey: .D_high
        )
        .frame(height: 280)
        .padding()
        .background(Color.black)
    }
}
