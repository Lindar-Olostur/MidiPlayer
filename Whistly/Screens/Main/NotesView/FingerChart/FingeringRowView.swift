
import SwiftUI

struct FingeringRowView: View {
    @Environment(MainContainer.self) private var viewModel
    
    let notes: [MIDINote]
    let currentBeat: Double
    let startBeatOffset: Double
    let beatWidth: CGFloat
    let rowHeight: CGFloat
    let totalWidth: CGFloat
    let offset: CGFloat
    let isPlaying: Bool
    let whistleKey: WhistleKey
    let viewWidth: CGFloat
    let scrollThreshold: CGFloat
    
    private let symbolRowHeight: CGFloat = 8
    
    init(
        notes: [MIDINote],
        currentBeat: Double,
        startBeatOffset: Double,
        beatWidth: CGFloat,
        rowHeight: CGFloat,
        totalWidth: CGFloat,
        offset: CGFloat,
        isPlaying: Bool,
        whistleKey: WhistleKey,
        viewWidth: CGFloat,
        scrollThreshold: CGFloat = 1
    ) {
        self.notes = notes
        self.currentBeat = currentBeat
        self.startBeatOffset = startBeatOffset
        self.beatWidth = beatWidth
        self.rowHeight = rowHeight
        self.totalWidth = totalWidth
        self.offset = offset
        self.isPlaying = isPlaying
        self.whistleKey = whistleKey
        self.viewWidth = viewWidth
        self.scrollThreshold = scrollThreshold
    }
    
    // Создаем массив всех "слотов" включая пустые места между нотами
    private var noteSlots: [(note: MIDINote?, beat: Double, width: CGFloat)] {
        var slots: [(MIDINote?, Double, CGFloat)] = []
        var currentBeat = startBeatOffset
        
        for note in notes {
            // Добавляем пустое место до ноты если нужно
            if note.startBeat > currentBeat {
                let gap = note.startBeat - currentBeat
                slots.append((nil, currentBeat, CGFloat(gap) * beatWidth))
                currentBeat = note.startBeat
            }
            
            // Добавляем саму ноту
            let width = max(CGFloat(note.duration) * beatWidth, 40)
            slots.append((note, note.startBeat, width))
            currentBeat = note.endBeat
        }
        
        return slots
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(noteSlots.enumerated()), id: \.offset) { index, slot in
                        if let note = slot.note {
                            FingeringImageView(
                                note: note,
                                width: slot.width,
                                whistleKey: whistleKey,
                                currentBeat: currentBeat
                            )
                            .frame(width: slot.width, height: rowHeight - symbolRowHeight - 2)
                            .padding(.vertical, 8)
                            .id("slot_\(index)")
                        } else {
                            Color.clear
                                .frame(width: slot.width, height: rowHeight)
                                .id("slot_\(index)")
                        }
                    }
                }
                .frame(height: rowHeight)
                .background(Color.fillQuartenary)
            }
            .onChange(of: currentBeat) { _, newValue in
                if isPlaying {
                    scrollToCurrentPosition(proxy: proxy, beat: newValue)
                }
            }
            .onChange(of: viewModel.scrollManager.scrollToStartTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("slot_0", anchor: .leading)
                }
            }
        }
    }
    
    private func scrollToCurrentPosition(proxy: ScrollViewProxy, beat: Double) {
        guard !notes.isEmpty else { return }
        
        let currentNoteIndex: Int
        let currentNote: MIDINote
        
        if let foundIndex = notes.firstIndex(where: { note in
            note.startBeat <= beat && note.endBeat > beat
        }) {
            currentNoteIndex = foundIndex
            currentNote = notes[currentNoteIndex]
        } else {
            if beat >= notes.last?.endBeat ?? 0 {
                currentNoteIndex = notes.count - 1
                currentNote = notes[currentNoteIndex]
            } else {
                return
            }
        }
        
        let remainingNotes = notes.count - currentNoteIndex - 1
        let lastScrolledNoteId = viewModel.scrollManager.lastScrolledNoteId
        
        if currentNoteIndex == 0 && lastScrolledNoteId != nil {
            viewModel.scrollManager.reset()
        }
        
        if remainingNotes < 1 {
            if lastScrolledNoteId != nil {
                viewModel.scrollManager.reset()
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("slot_0", anchor: .leading)
                }
            }
            return
        }
        
        let lastVisibleNoteIndex: Int
        
        if let lastScrolledId = lastScrolledNoteId,
           let lastScrolledIndex = notes.firstIndex(where: { $0.id == lastScrolledId }),
           let lastScrolledSlotIndex = noteSlots.firstIndex(where: { $0.note?.id == lastScrolledId }) {
            var accumulatedWidth: CGFloat = 0
            var foundNoteIndex = lastScrolledIndex
            
            for slotIndex in lastScrolledSlotIndex..<noteSlots.count {
                let slot = noteSlots[slotIndex]
                accumulatedWidth += slot.width
                
                if let note = slot.note,
                   let noteIndex = notes.firstIndex(where: { $0.id == note.id }) {
                    if accumulatedWidth >= viewWidth * scrollThreshold {
                        foundNoteIndex = noteIndex
                        break
                    }
                }
            }
            
            lastVisibleNoteIndex = foundNoteIndex
        } else {
            var accumulatedWidth: CGFloat = 0
            var foundNoteIndex = 0
            
            for slot in noteSlots {
                accumulatedWidth += slot.width
                
                if let note = slot.note,
                   let noteIndex = notes.firstIndex(where: { $0.id == note.id }) {
                    if accumulatedWidth >= viewWidth * scrollThreshold {
                        foundNoteIndex = noteIndex
                        break
                    }
                }
            }
            
            lastVisibleNoteIndex = foundNoteIndex
        }
        
        guard currentNoteIndex >= lastVisibleNoteIndex else { return }
        
        if lastScrolledNoteId == currentNote.id {
            return
        }
        
        guard let slotIndex = noteSlots.firstIndex(where: { slot in
            slot.note?.id == currentNote.id
        }) else { return }
        
        guard slotIndex < noteSlots.count else { return }
        
        viewModel.scrollManager.setLastScrolledNoteId(currentNote.id)
        
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("slot_\(slotIndex)", anchor: .leading)
        }
    }
}


//#Preview {
//    FingeringRowView(
//        notes: [
//            MIDINote(pitch: 69, velocity: 80, startBeat: 0, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 1, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 2, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 3, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 4, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 5, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 6, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 7, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 8, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 9, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 10, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 11, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 12, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 13, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 14, duration: 2, channel: 0),
//            MIDINote(pitch: 69, velocity: 80, startBeat: 15, duration: 2, channel: 0)
//        ],
//        currentBeat: 1,
//        startBeatOffset: 0,
//        beatWidth: 40,
//        rowHeight: 70,
//        totalWidth: 200,
//        offset: 0,
//        isPlaying: false,
//        whistleKey: .D
//    )
//    .frame(width: 200, height: 70)
//    .background(Color.gray.opacity(0.1))
//}
