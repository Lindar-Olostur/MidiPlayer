import SwiftUI

@Observable
final class ScrollManager {
    private(set) var lastScrolledNoteId: UUID?
    private(set) var scrollToStartTrigger: Int = 0
    
    func reset() {
        lastScrolledNoteId = nil
    }
    
    func setLastScrolledNoteId(_ id: UUID?) {
        lastScrolledNoteId = id
    }
    
    func scrollToStart() {
        reset()
        scrollToStartTrigger += 1
    }
}

