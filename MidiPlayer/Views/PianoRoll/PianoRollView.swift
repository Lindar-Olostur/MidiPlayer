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
                ScrollView(.horizontal, showsIndicators: false) {
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
//                .gesture(
//                    // Pinch to zoom
//                    MagnificationGesture()
//                        .onChanged { value in
//                            let newScale = lastScale * value
//                            scale = min(max(newScale, minScale), maxScale)
//                            
//                            // Корректируем offset при зуме чтобы центр оставался на месте
//                            let newMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
//                            offset = min(offset, newMaxOffset)
//                        }
//                        .onEnded { _ in
//                            lastScale = scale
//                            lastOffset = offset
//                        }
//                )
//                .simultaneousGesture(
//                    // Drag to pan (когда зум > 1)
//                    DragGesture()
//                        .onChanged { value in
//                            if scale > 1.0 {
//                                let newOffset = lastOffset - value.translation.width
//                                let currentMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
//                                offset = min(max(0, newOffset), currentMaxOffset)
//                            }
//                        }
//                        .onEnded { _ in
//                            lastOffset = offset
//                        }
//                )
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
//        .frame(height: 300)
        .padding()
        .background(Color.black)
    }
}

