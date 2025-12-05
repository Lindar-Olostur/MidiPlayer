//
//  FingeringRowView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//
import SwiftUI

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
    
    private let symbolRowHeight: CGFloat = 8  // Минимальная высота для индикатора
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Фон для аппликатур
            Color.white.opacity(0.15)
            
            // Аппликатуры
            ForEach(notes) { note in
                let x = CGFloat(note.startBeat - startBeatOffset) * beatWidth
                let width = max(CGFloat(note.duration) * beatWidth, 40)
                
                FingeringImageView(
                    note: note,
                    width: width,
                    whistleKey: whistleKey,
                    currentBeat: currentBeat
                )
                .frame(width: width, height: rowHeight - symbolRowHeight - 2)
                .offset(x: x, y: 1)
                .padding(.vertical, 8)
            }
        }
//        .frame(width: totalWidth, height: rowHeight)
        .offset(x: -offset)
    }
}

#Preview {
    FingeringRowView(
        notes: [
            MIDINote(pitch: 62, velocity: 80, startBeat: 0, duration: 2, channel: 0),
            MIDINote(pitch: 69, velocity: 80, startBeat: 2, duration: 2, channel: 0)
        ],
        currentBeat: 1,
        startBeatOffset: 0,
        beatWidth: 40,
        rowHeight: 70,
        totalWidth: 200,
        offset: 0,
        isPlaying: false,
        whistleKey: .G
    )
    .frame(width: 200, height: 70)
    .background(Color.gray.opacity(0.1))
}
