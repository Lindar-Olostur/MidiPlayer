//
//  FingerChartView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import SwiftUI

enum ChartScale {
    case landscape, portrait
    
    var fingeringRowHeight: CGFloat {
        switch self {
        case .portrait: 70
        case .landscape: 150
        }
    }
}

struct FingerChartView: View {
    let midiInfo: MIDIFileInfo
    let currentBeat: Double
    let startMeasure: Int
    let endMeasure: Int
    let isPlaying: Bool
    let whistleKey: WhistleKey
    
    // Настройки
    var mode: ChartScale = .portrait
    private let noteHeight: CGFloat = 6
    private let pianoKeyWidth: CGFloat = 35
    
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
                        .frame(width: pianoKeyWidth, height: mode.fingeringRowHeight)
                        .opacity(mode == .portrait ? 1 : 0)
                        .background(Color.white)
                    
                    // Ряд аппликатур (синхронно скроллится с пианороллом)
                    FingeringRowView(
                        notes: visibleNotes,
                        currentBeat: currentBeat,
                        startBeatOffset: startBeatOffset,
                        beatWidth: scaledBeatWidth,
                        rowHeight: mode.fingeringRowHeight,
                        totalWidth: totalContentWidth,
                        offset: min(max(0, offset), maxOffset),
                        isPlaying: isPlaying,
                        whistleKey: whistleKey
                    )
                    .frame(height: mode.fingeringRowHeight)
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
                    VStack {
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
                            if mode == .portrait {
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
                        }
                        .frame(width: totalContentWidth, height: pianoRollHeight)
                        .offset(x: -min(max(0, offset), maxOffset))
                    }
                    .clipped()
//                    .gesture(
//                        MagnificationGesture()
//                            .onChanged { value in
//                                let newScale = lastScale * value
//                                scale = min(max(newScale, minScale), maxScale)
//                                let newMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
//                                offset = min(offset, newMaxOffset)
//                            }
//                            .onEnded { _ in
//                                lastScale = scale
//                                lastOffset = offset
//                            }
//                    )
//                    .simultaneousGesture(
//                        DragGesture()
//                            .onChanged { value in
//                                if scale > 1.0 {
//                                    let newOffset = lastOffset - value.translation.width
//                                    let currentMaxOffset = max(0, CGFloat(visibleBeats) * baseWidth * scale - availableWidth)
//                                    offset = min(max(0, newOffset), currentMaxOffset)
//                                }
//                            }
//                            .onEnded { _ in
//                                lastOffset = offset
//                            }
//                    )
//                    .onTapGesture(count: 2) {
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            scale = 1.0
//                            lastScale = 1.0
//                            offset = 0
//                            lastOffset = 0
//                        }
//                    }
                }
            }
//            // Индикатор зума
//            .overlay(
//                VStack {
//                    HStack {
//                        Spacer()
//                        if scale != 1.0 {
//                            Text("\(Int(scale * 100))%")
//                                .font(.system(size: 10, weight: .medium))
//                                .foregroundColor(.white.opacity(0.6))
//                                .padding(.horizontal, 6)
//                                .padding(.vertical, 2)
//                                .background(Capsule().fill(Color.black.opacity(0.5)))
//                                .padding(6)
//                        }
//                    }
//                    Spacer()
//                }
//            )
        }
        .frame(maxHeight: 210)//TODO auto set height
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
        FingerChartView(
            midiInfo: info,
            currentBeat: 4,
            startMeasure: 4,
            endMeasure: 5,
            isPlaying: true,
            whistleKey: .C
        )
    }
}
