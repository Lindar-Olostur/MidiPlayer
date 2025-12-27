import SwiftUI

struct PianoRollView: View {
    @Environment(MainContainer.self) private var viewModel
    let midiInfo: MIDIFileInfo
    
    private let noteHeight: CGFloat = 8
    private let baseBeatWidth: CGFloat = 40
    private let pianoKeyWidth: CGFloat = 50
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 4.0
    
    private var visibleNotes: [MIDINote] {
        let startBeat = Double(viewModel.sequencer.startMeasure - 1) * Double(midiInfo.beatsPerMeasure)
        let endBeat = Double(viewModel.sequencer.endMeasure) * Double(midiInfo.beatsPerMeasure)
        return midiInfo.allNotes.filter { note in
            note.endBeat > startBeat && note.startBeat < endBeat
        }
    }
    
    private var pitchRange: ClosedRange<UInt8> {
        let minP = max(0, Int(midiInfo.minPitch) + 0)//2
        let maxP = min(127, Int(midiInfo.maxPitch) - 0)//2
        return UInt8(minP)...UInt8(maxP)
    }
    
    private var totalRows: Int {
        Int(pitchRange.upperBound - pitchRange.lowerBound) + 1
    }
    
    private var visibleBeats: Double {
        Double((viewModel.sequencer.endMeasure - viewModel.sequencer.startMeasure + 1) * midiInfo.beatsPerMeasure)
    }
    
    private var startBeatOffset: Double {
        Double((viewModel.sequencer.startMeasure - 1) * midiInfo.beatsPerMeasure)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - pianoKeyWidth
            let baseWidth = availableWidth / CGFloat(visibleBeats)
            let scaledBeatWidth = baseWidth
            let totalContentWidth = CGFloat(visibleBeats) * scaledBeatWidth
            let totalHeight = CGFloat(totalRows) * noteHeight
            
            let maxOffset = max(0, totalContentWidth - availableWidth)
            
            HStack(spacing: 0) {
                PianoKeysView(
                    pitchRange: pitchRange,
                    noteHeight: noteHeight
                )
                .frame(width: pianoKeyWidth)
                
//                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        GridBackground(
                            rows: totalRows,
                            beats: Int(visibleBeats),
                            noteHeight: noteHeight,
                            beatWidth: scaledBeatWidth,
                            beatsPerMeasure: midiInfo.beatsPerMeasure,
                            pitchRange: pitchRange
                        )
                        
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
                        
                        if viewModel.sequencer.isPlaying || viewModel.sequencer.currentBeat > 0 {
                            let cursorX = CGFloat(viewModel.sequencer.currentBeat - startBeatOffset) * scaledBeatWidth
                            Rectangle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 2, height: totalHeight)
                                .offset(x: cursorX)
                        }
                    }
                    .frame(width: totalContentWidth, height: totalHeight)
                    .offset(x: -min(0, maxOffset))
//                }
//                .clipped()
            }
        }
        .frame(maxHeight: .infinity)
        .background(.fillQuartenary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func isNoteActive(_ note: MIDINote) -> Bool {
        let lookAhead: Double = 0//0.75
        return viewModel.sequencer.currentBeat + lookAhead >= note.startBeat && viewModel.sequencer.currentBeat < note.endBeat
    }
}

#Preview {
    let container = MainContainer()
    if let url = Bundle.main.url(forResource: "testTune", withExtension: "abc"),
       let tunes = ABCParser.parseFile(url: url),
       let firstTune = tunes.first {
        let info = ABCParser.toMIDIFileInfo(firstTune, transpose: 0)
        PianoRollView(
            midiInfo: info
        )
        .frame(height: 156)
        .padding()
        .background(Color.bgPrimary)
        .environment(container)
    } else {
        Text("Preview unavailable")
            .foregroundColor(.gray)
            .frame(height: 300)
            .padding()
            .background(Color.black)
            .environment(container)
    }
}

