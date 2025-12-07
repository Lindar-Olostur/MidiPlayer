//
//  TuneAndWhistleSectionView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import SwiftUI

struct TuneAndWhistleSectionView: View {
    @Binding var whistleKey: WhistleKey
    let playableKeys: [String]
    let viewMode: ViewMode
    let currentTuneKey: String
    let currentDisplayedKey: String
    let onKeySelect: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Выбор строя вистла
                WhistleKeyPicker(whistleKey: $whistleKey)

                // Доступные тональности мелодии для выбранного вистла
                if !playableKeys.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(playableKeys, id: \.self) { key in
                                Button(action: {
                                    onKeySelect(key)
                                }) {
                                    Text(key)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(key == currentDisplayedKey ? .orange : .white.opacity(0.8))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 13)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(key == currentDisplayedKey ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 30)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    TuneAndWhistleSectionView(
        whistleKey: .constant(.D_high),
        playableKeys: ["C", "D", "G", "A"],
        viewMode: .fingerChart,
        currentTuneKey: "C",
        currentDisplayedKey: "C",
        onKeySelect: { _ in }
    )
    .frame(width: 400)
}
