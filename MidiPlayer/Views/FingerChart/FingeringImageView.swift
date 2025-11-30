//
//  FingeringImageView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//
import SwiftUI

struct FingeringImageView: View {
    let note: MIDINote
    let width: CGFloat
    let whistleKey: WhistleKey
    
    var body: some View {
        // Проверяем, находится ли нота в диапазоне свистля
        let pitchRange = whistleKey.pitchRange
        let isInRange = note.pitch >= pitchRange.min && note.pitch <= pitchRange.max

        if isInRange, let degree = WhistleConverter.pitchToFingering(note.pitch, whistleKey: whistleKey) {
            // Нота в диапазоне и playable - показываем аппликатуру
            Image(degree.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Нота вне диапазона или не playable
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

#Preview {
    HStack {
        // Нота в диапазоне D свистля (D3-B4 = 50-71)
        FingeringImageView(
            note: MIDINote(pitch: 62, velocity: 80, startBeat: 0, duration: 2, channel: 0), // D4
            width: 60,
            whistleKey: .D_high
        )
        // Нота вне диапазона D свистля
        FingeringImageView(
            note: MIDINote(pitch: 74, velocity: 80, startBeat: 0, duration: 2, channel: 0), // D5 - вне диапазона
            width: 60,
            whistleKey: .D_high
        )
        // Хроматическая нота в диапазоне
        FingeringImageView(
            note: MIDINote(pitch: 63, velocity: 80, startBeat: 0, duration: 2, channel: 0), // D#4 - хроматическая
            width: 60,
            whistleKey: .D_high
        )
    }
    .frame(height: 60)
    .padding()
    .background(Color.white)
}
