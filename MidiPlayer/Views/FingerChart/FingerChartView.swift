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
        case .portrait: 90
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
    private let pianoKeyWidth: CGFloat = 35
    
    private var visibleNotes: [MIDINote] {
        let startBeat = Double(startMeasure - 1) * Double(midiInfo.beatsPerMeasure)
        let endBeat = Double(endMeasure) * Double(midiInfo.beatsPerMeasure)
        return midiInfo.allNotes.filter { note in
            note.endBeat > startBeat && note.startBeat < endBeat
        }
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
            let totalContentWidth = CGFloat(visibleBeats) * baseWidth
            
            FingeringRowView(
                notes: visibleNotes,
                currentBeat: currentBeat,
                startBeatOffset: startBeatOffset,
                beatWidth: baseWidth,
                rowHeight: mode.fingeringRowHeight,
                totalWidth: totalContentWidth,
                offset: 0,
                isPlaying: isPlaying,
                whistleKey: whistleKey
            )
//                    .frame(height: mode.fingeringRowHeight)
            .clipped()
        }
        .frame(maxHeight: 110)
//        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
