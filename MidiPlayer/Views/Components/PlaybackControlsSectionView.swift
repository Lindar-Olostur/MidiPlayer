//
//  PlaybackControlsSectionView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import SwiftUI

struct PlaybackControlsSectionView: View {
    let isPlaying: Bool
    let isLooping: Bool
    let currentMeasure: Int
    let beatsPerMeasure: Int
    let endBeat: Double
    let onRewind: () -> Void
    let onStop: () -> Void
    let onPlayPause: () -> Void
    let onToggleLoop: () -> Void
    let onNextMeasure: () -> Void

    var body: some View {
        HStack(spacing: 25) {
            ControlButton(systemName: "backward.end.fill", size: 20) {
                onRewind()
            }

            ControlButton(systemName: "stop.fill", size: 20) {
                onStop()
            }

            // Play/Pause
            Button(action: onPlayPause) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }

            // Loop
            Button(action: onToggleLoop) {
                ZStack {
                    Circle()
                        .fill(isLooping
                              ? Color.cyan.opacity(0.2)
                              : Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)

                    Image(systemName: isLooping ? "repeat.circle.fill" : "repeat")
                        .font(.system(size: 18))
                        .foregroundColor(isLooping ? .cyan : .white.opacity(0.6))
                }
            }

            ControlButton(systemName: "forward.end.fill", size: 20) {
                onNextMeasure()
            }
        }
        .padding(.bottom, 25)
    }
}

#Preview {
    PlaybackControlsSectionView(
        isPlaying: false,
        isLooping: true,
        currentMeasure: 2,
        beatsPerMeasure: 4,
        endBeat: 32,
        onRewind: {},
        onStop: {},
        onPlayPause: {},
        onToggleLoop: {},
        onNextMeasure: {}
    )
}









