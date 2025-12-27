import SwiftUI

enum ScrollAction {
    case none
    case scrollToPage(Int)
    case scrollToStart(instant: Bool)
}

@Observable
final class ScrollManager {
    private(set) var lastScrolledNoteId: UUID?
    private(set) var lastScrolledPage: Int = -1
    private(set) var scrollToStartTrigger: Int = 0
    private(set) var instantScroll: Bool = false
    
    func reset() {
        lastScrolledNoteId = nil
        lastScrolledPage = -1
    }
    
    func setLastScrolledNoteId(_ id: UUID?) {
        lastScrolledNoteId = id
    }
    
    func setLastScrolledPage(_ page: Int) {
        lastScrolledPage = page
    }
    
    func scrollToStart(instant: Bool = false) {
        reset()
        instantScroll = instant
        scrollToStartTrigger += 1
    }
    
    func shouldScrollToPage(currentPage: Int, remainingItems: Int) -> Bool {
        if remainingItems < 1 {
            return false
        }
        
        if currentPage == 0 && lastScrolledNoteId != nil {
            return false
        }
        
        guard currentPage > lastScrolledPage else { return false }
        
        return true
    }
    
    func shouldScrollToStart(currentPage: Int, remainingItems: Int) -> Bool {
        if remainingItems < 1 && lastScrolledNoteId != nil {
            return true
        }
        
        if currentPage == 0 && lastScrolledNoteId != nil {
            return true
        }
        
        return false
    }
    
    func handleBeatJump(oldBeat: Double, newBeat: Double, startBeatOffset: Double, pageSize: Double) -> Bool {
        if oldBeat > newBeat && oldBeat - newBeat > 10 {
            let oldPage = oldBeat > startBeatOffset ? Int((oldBeat - startBeatOffset) / pageSize) : 0
            let newPage = Int((newBeat - startBeatOffset) / pageSize)
            
            if oldPage > 0 && newPage == 0 {
                return true
            }
        }
        
        return false
    }
}

