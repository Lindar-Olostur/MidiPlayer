
import SwiftUI

struct FingeringRowView: View {
    @Environment(MainContainer.self) private var viewModel
    
    let notes: [MIDINote]
    let currentBeat: Double
    let startBeatOffset: Double
    let baselineBeatWidth: CGFloat
    let rowHeight: CGFloat
    let totalWidth: CGFloat
    let offset: CGFloat
    let isPlaying: Bool
    let whistleKey: WhistleKey
    let viewWidth: CGFloat
    let beatsPerMeasure: Int
    
    private let symbolRowHeight: CGFloat = 10
    private let minNoteWidth: CGFloat = 20 // Увеличим минимум
    private let targetNoteWidth: CGFloat = 40 // Целевая ширина для комфортного чтения
    
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
        beatsPerMeasure: Int
    ) {
        self.notes = notes
        self.currentBeat = currentBeat
        self.startBeatOffset = startBeatOffset
        self.baselineBeatWidth = beatWidth
        self.rowHeight = rowHeight
        self.totalWidth = totalWidth
        self.offset = offset
        self.isPlaying = isPlaying
        self.whistleKey = whistleKey
        self.viewWidth = viewWidth
        self.beatsPerMeasure = beatsPerMeasure
    }
    
    // Подсчитываем реальное количество слотов в диапазоне
    private func countActualSlotsInRange(startBeat: Double, endBeat: Double) -> Int {
        let notesInRange = notes.filter { note in
            note.startBeat >= startBeat && note.startBeat < endBeat
        }
        
        guard !notesInRange.isEmpty else { return 0 }
        
        var slotCount = 0
        var currentBeat = startBeat
        
        for note in notesInRange {
            if note.startBeat > currentBeat {
                slotCount += 1 // пауза
            }
            slotCount += 1 // нота
            currentBeat = min(note.endBeat, endBeat)
        }
        
        if currentBeat < endBeat {
            slotCount += 1 // пауза в конце
        }
        
        return slotCount
    }
    
    // Вычисляем оптимальный размер страницы
    private var optimalPageSizeInBeats: Double {
        let pageSizeInMeasures: [Double] = [8, 4, 2, 1, 0.5, 0.25]
        
        for measuresCount in pageSizeInMeasures {
            let pageSizeInBeats = measuresCount * Double(beatsPerMeasure)
            
            // Проверяем количество слотов на первых страницах
            var maxSlots = 0
            let maxPagesToCheck = min(5, Int(ceil((notes.last?.endBeat ?? 0 - startBeatOffset) / pageSizeInBeats)))
            
            for pageIndex in 0..<maxPagesToCheck {
                let pageStart = startBeatOffset + Double(pageIndex) * pageSizeInBeats
                let pageEnd = pageStart + pageSizeInBeats
                let slotsOnPage = countActualSlotsInRange(startBeat: pageStart, endBeat: pageEnd)
                maxSlots = max(maxSlots, slotsOnPage)
            }
            
            if maxSlots == 0 { continue }
            
            // Вычисляем какую ширину получит каждый слот
            let widthPerSlot = viewWidth / CGFloat(maxSlots)
            
            // Проверяем что ширина >= минимальной
            if widthPerSlot >= minNoteWidth {
                print("✅ Selected: \(measuresCount) measures (\(pageSizeInBeats) beats)")
                print("   Max slots: \(maxSlots), width per slot: \(widthPerSlot)")
                return pageSizeInBeats
            }
            
            print("❌ Rejected: \(measuresCount) measures - max slots: \(maxSlots), width per slot: \(widthPerSlot) < \(minNoteWidth)")
        }
        
        let fallback = 0.25 * Double(beatsPerMeasure)
        print("⚠️ Using fallback: 0.25 measures")
        return fallback
    }
    
    // Разбиваем ноты на страницы
    private var notePages: [[MIDINote]] {
        var pages: [[MIDINote]] = []
        let pageSize = optimalPageSizeInBeats
        
        var currentPageStartBeat = startBeatOffset
        var currentPage: [MIDINote] = []
        
        for note in notes {
            let pageEnd = currentPageStartBeat + pageSize
            
            if note.startBeat >= currentPageStartBeat && note.startBeat < pageEnd {
                currentPage.append(note)
            } else if note.startBeat >= pageEnd {
                if !currentPage.isEmpty {
                    pages.append(currentPage)
                }
                
                let pagesFromStart = floor((note.startBeat - startBeatOffset) / pageSize)
                currentPageStartBeat = startBeatOffset + pagesFromStart * pageSize
                currentPage = [note]
            }
        }
        
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        return pages
    }
    
    // Создаем слоты - распределяем ширину РАВНОМЕРНО между слотами
    private var pages: [(pageIndex: Int, slots: [(note: MIDINote?, width: CGFloat, slotId: String)])] {
        var result: [(Int, [(MIDINote?, CGFloat, String)])] = []
        let pageSize = optimalPageSizeInBeats
        
        for (pageIndex, pageNotes) in notePages.enumerated() {
            var slots: [(note: MIDINote?, id: String)] = []
            
            let pageStartBeat = startBeatOffset + Double(pageIndex) * pageSize
            let pageEndBeat = pageStartBeat + pageSize
            var currentBeat = pageStartBeat
            
            // Собираем слоты БЕЗ ширины
            for note in pageNotes {
                // Пауза перед нотой
                if note.startBeat > currentBeat {
                    slots.append((nil, "page\(pageIndex)_gap\(slots.count)"))
                    currentBeat = note.startBeat
                }
                
                // Нота
                let noteEndOnPage = min(note.endBeat, pageEndBeat)
                if noteEndOnPage > currentBeat {
                    slots.append((note, "page\(pageIndex)_note\(note.id)"))
                    currentBeat = noteEndOnPage
                }
                
                if currentBeat >= pageEndBeat {
                    break
                }
            }
            
            // Пауза в конце
            if currentBeat < pageEndBeat && !slots.isEmpty {
                slots.append((nil, "page\(pageIndex)_gap_end"))
            }
            
            // Распределяем ширину РАВНОМЕРНО между всеми слотами
            let slotCount = slots.count
            guard slotCount > 0 else { continue }
            
            let widthPerSlot = viewWidth / CGFloat(slotCount)
            
            let finalSlots = slots.map { slot -> (MIDINote?, CGFloat, String) in
                return (slot.note, widthPerSlot, slot.id)
            }
            
            result.append((pageIndex, finalSlots))
            
            let totalWidth = finalSlots.reduce(0) { $0 + $1.1 }
            let noteCount = finalSlots.filter { $0.0 != nil }.count
            let gapCount = finalSlots.count - noteCount
            print("📄 Page \(pageIndex): \(finalSlots.count) slots (\(noteCount) notes, \(gapCount) gaps)")
            print("   Width per slot: \(widthPerSlot), total: \(totalWidth)")
        }
        
        return result
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(pages, id: \.pageIndex) { page in
                        HStack(spacing: 0) {
                            ForEach(Array(page.slots.enumerated()), id: \.offset) { index, slot in
                                if let note = slot.note {
                                    FingeringImageView(
                                        note: note,
                                        width: slot.width,
                                        whistleKey: whistleKey,
                                        currentBeat: currentBeat
                                    )
                                    .frame(width: slot.width, height: rowHeight - symbolRowHeight - 2)
                                    .padding(.vertical, 8)
                                    .id(slot.slotId)
                                } else {
                                    Color.clear
                                        .frame(width: slot.width, height: rowHeight)
                                        .id(slot.slotId)
                                }
                            }
                        }
                        .frame(width: viewWidth)
                        .id("page_\(page.pageIndex)")
                    }
                }
            }
            .onChange(of: currentBeat) { oldValue, newValue in
                let pageSize = optimalPageSizeInBeats
                
                if viewModel.scrollManager.handleBeatJump(
                    oldBeat: oldValue,
                    newBeat: newValue,
                    startBeatOffset: startBeatOffset,
                    pageSize: pageSize
                ) {
                    viewModel.scrollManager.scrollToStart(instant: true)
                }
                
                if isPlaying {
                    scrollToCurrentPosition(proxy: proxy, beat: newValue)
                }
            }
            .onChange(of: viewModel.scrollManager.scrollToStartTrigger) { _, _ in
                let isInstant = viewModel.scrollManager.instantScroll
                if isInstant {
                    proxy.scrollTo("page_0", anchor: .leading)
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("page_0", anchor: .leading)
                    }
                }
            }
            .onAppear {
                let measuresInPage = optimalPageSizeInBeats / Double(beatsPerMeasure)
                print("📄 Final page size: \(measuresInPage) measures (\(optimalPageSizeInBeats) beats)")
                print("📄 Total pages: \(pages.count)")
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
        
        let pageSize = optimalPageSizeInBeats
        let currentPage = Int((currentNote.startBeat - startBeatOffset) / pageSize)
        let remainingNotes = notes.count - currentNoteIndex - 1
        
        if viewModel.scrollManager.shouldScrollToStart(
            currentPage: currentPage,
            remainingItems: remainingNotes
        ) {
            viewModel.scrollManager.reset()
            proxy.scrollTo("page_0", anchor: .leading)
            return
        }
        
        if !viewModel.scrollManager.shouldScrollToPage(
            currentPage: currentPage,
            remainingItems: remainingNotes
        ) {
            return
        }
        
        guard currentPage < pages.count else { return }
        
        if let lastScrolledId = viewModel.scrollManager.lastScrolledNoteId,
           let lastScrolledNote = notes.first(where: { $0.id == lastScrolledId }) {
            let lastScrolledPage = Int((lastScrolledNote.startBeat - startBeatOffset) / pageSize)
            viewModel.scrollManager.setLastScrolledPage(lastScrolledPage)
        }
        
        viewModel.scrollManager.setLastScrolledNoteId(currentNote.id)
        viewModel.scrollManager.setLastScrolledPage(currentPage)
        
        let measuresInPage = pageSize / Double(beatsPerMeasure)
        print("📄 Scrolling to page \(currentPage + 1)/\(pages.count) (\(measuresInPage) measures)")
        
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("page_\(currentPage)", anchor: .leading)
        }
    }
}

#Preview {
    let testNotes: [MIDINote] = [
        MIDINote(pitch: 69, velocity: 80, startBeat: 0, duration: 1, channel: 0),
        MIDINote(pitch: 71, velocity: 80, startBeat: 1, duration: 1, channel: 0),
        MIDINote(pitch: 73, velocity: 80, startBeat: 2, duration: 1, channel: 0),
        MIDINote(pitch: 74, velocity: 80, startBeat: 3, duration: 1, channel: 0),
        MIDINote(pitch: 76, velocity: 80, startBeat: 4, duration: 1, channel: 0),
        MIDINote(pitch: 78, velocity: 80, startBeat: 5, duration: 1, channel: 0),
        MIDINote(pitch: 80, velocity: 80, startBeat: 6, duration: 1, channel: 0),
        MIDINote(pitch: 81, velocity: 80, startBeat: 7, duration: 1, channel: 0),
        MIDINote(pitch: 83, velocity: 80, startBeat: 8, duration: 1, channel: 0),
        MIDINote(pitch: 85, velocity: 80, startBeat: 9, duration: 1, channel: 0),
        MIDINote(pitch: 86, velocity: 80, startBeat: 10, duration: 1, channel: 0),
        MIDINote(pitch: 88, velocity: 80, startBeat: 11, duration: 1, channel: 0),
        MIDINote(pitch: 69, velocity: 80, startBeat: 12, duration: 1, channel: 0),
        MIDINote(pitch: 71, velocity: 80, startBeat: 13, duration: 1, channel: 0),
        MIDINote(pitch: 73, velocity: 80, startBeat: 14, duration: 1, channel: 0),
        MIDINote(pitch: 74, velocity: 80, startBeat: 15, duration: 1, channel: 0)
    ]
    
    FingeringRowView(
        notes: testNotes,
        currentBeat: 2.5,
        startBeatOffset: 0,
        beatWidth: 40,
        rowHeight: 135,
        totalWidth: 640,
        offset: 0,
        isPlaying: false,
        whistleKey: .D,
        viewWidth: 320,
        beatsPerMeasure: 4
    )
    .frame(width: 320, height: 135)
    .padding()
    .background(Color.bgPrimary)
    .environment(MainContainer())
}
