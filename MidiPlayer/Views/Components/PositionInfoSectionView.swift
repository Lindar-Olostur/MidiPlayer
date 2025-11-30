//
//  PositionInfoSectionView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import SwiftUI

struct PositionInfoSectionView: View {
    let currentBeat: Double
    let currentMeasure: Int
    let totalMeasures: Int
    let tempo: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Beat")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.1f", currentBeat))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Measure")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(currentMeasure)/\(totalMeasures)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Tempo")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(tempo))")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    PositionInfoSectionView(
        currentBeat: 12.5,
        currentMeasure: 2,
        totalMeasures: 8,
        tempo: 120
    )
}



