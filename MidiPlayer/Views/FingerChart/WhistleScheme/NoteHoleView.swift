//
//  NoteHoleView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 04.12.2025.
//

import SwiftUI

enum HoleState: CaseIterable {
    case opened
    case halfClosed
    case closed
}

struct NoteHoleView: View {
    @ObservedObject var theme = FingerChartStyleManager.shared
    let state: HoleState
    var size: CGFloat?
    var isActive: Bool
    var isSelfColored: Bool = false
    
    var body: some View {
        Group {
            if let size = size {
                holeView(size: size)
            } else {
                GeometryReader { geometry in
                    let holeSize = min(geometry.size.width, geometry.size.height)
                    holeView(size: holeSize)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
    
    @ViewBuilder
    private func holeView(size: CGFloat) -> some View {
        let lineWidth = max(
            theme.minLineWidth,
            size * theme.lineWidthCoefficient * 1.5
        )
        
        Circle()
            .stroke(lineWidth: lineWidth)
            .fill(theme.colors.holeStroke)
            .overlay {
                switch state {
                case .opened: Circle()
                        .fill(theme.colors.openHole)
                case .closed:
                    if isActive && isSelfColored {
                        Circle()
                            .fill(.orange)
                            .shadow(color: Color.orange.opacity(0.8), radius: 4)
                            .animation(.easeInOut(duration: 0.1), value: isActive)
                    } else {
                        Circle()
                            .fill(theme.colors.closedHole)
                    }
                case .halfClosed:
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .rotation(.degrees(90))
                        .fill(theme.colors.halfClosedHole)
                }
            }
            .frame(width: size, height: size)
    }
}

#Preview {
    NoteHoleView(state: .closed, isActive: false, isSelfColored: true)
        .frame(width: 130, height: 130)
}
