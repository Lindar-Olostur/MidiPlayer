//
//  HeaderSectionView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//

import SwiftUI

struct HeaderSectionView: View {
    let tuneName: String?
    @Binding var sourceType: SourceType
    let onSourceChange: (SourceType) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whistly")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.7, green: 0.5, blue: 1.0),
                                Color(red: 0.4, green: 0.8, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let tune = tuneName {
                    Text(tune)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Переключатель MIDI/ABC
            Picker("Source", selection: $sourceType) {
                ForEach(SourceType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .onChange(of: sourceType) { _, newValue in
                onSourceChange(newValue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

#Preview {
    HeaderSectionView(
        tuneName: "Test Tune",
        sourceType: .constant(.midi),
        onSourceChange: { _ in }
    )
}



