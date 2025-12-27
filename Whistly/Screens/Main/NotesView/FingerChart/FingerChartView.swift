import SwiftUI

enum ChartScale {
    case landscape, portrait
    
    var fingeringRowHeight: CGFloat {
        switch self {
        case .portrait: 135
        case .landscape: 150
        }
    }
}

struct FingerChartView: View {
    @Environment(MainContainer.self) private var viewModel
    let midiInfo: MIDIFileInfo
    var currentBeat: Double {
        viewModel.sequencer.currentBeat
    }
    var startMeasure: Int {
        viewModel.sequencer.startMeasure
    }
    var endMeasure: Int {
        viewModel.sequencer.endMeasure
    }
    var isPlaying: Bool {
        viewModel.sequencer.isPlaying
    }
    var whistleKey: WhistleKey
    
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
            let baseWidth = max(availableWidth / CGFloat(visibleBeats), 40)
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
                whistleKey: whistleKey,
                viewWidth: availableWidth,
                beatsPerMeasure: midiInfo.beatsPerMeasure
            )
            .padding(8)
        }
//        .frame(maxHeight: .infinity)
        .background(Color.fillQuartenary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    if let url = Bundle.main.url(forResource: "testTune", withExtension: "abc"), let tune = ABCParser.parseFile(url: url)?.first {
        FingerChartView(midiInfo: ABCParser.toMIDIFileInfo(tune), whistleKey: .D)
        .environment(MainContainer())
    }
}
