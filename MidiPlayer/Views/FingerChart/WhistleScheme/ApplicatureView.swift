//
//  ApplicatureView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 04.12.2025.
//

import SwiftUI

struct ApplicatureView: View {
    @ObservedObject var theme = FingerChartStyleManager.shared
    let note: WhistleScaleDegree
    let isActive: Bool
    var colored: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            // Используем высоту для вычисления размеров, чтобы не зависеть от ширины (длительности ноты)
            let viewHeight = geometry.size.height
            let viewWidth = geometry.size.width
            
            // Вычисляем адаптивные размеры на основе высоты
            // Используем коэффициент относительно высоты для стабильного размера
            let baseSize = viewHeight * 0.12  // Базовый размер относительно высоты
            let holeSize = max(
                theme.minHoleSize,
                baseSize
            )
            let holeSpacing = baseSize * theme.holeSpacingCoefficient * 2
            let circleStrokeWidth = max(
                theme.minLineWidth,
                holeSize * theme.lineWidthCoefficient * 2
            )
            let octaveLineWidth = max(
                theme.minLineWidth,
                baseSize * theme.octaveLineWidthCoefficient
            )
            
            VStack(alignment: .center, spacing: holeSpacing) {
                Group {
                    NoteHoleView(state: note.holesArray[0], size: holeSize, isActive: isActive, isSelfColored: colored)
                    NoteHoleView(state: note.holesArray[1], size: holeSize, isActive: isActive, isSelfColored: colored)
                    NoteHoleView(state: note.holesArray[2], size: holeSize, isActive: isActive, isSelfColored: colored)
                        .padding(.bottom, -circleStrokeWidth * 0.6)
                }
                .shadow(color: Color.orange.opacity((note == .VII && isActive) ? 1 : 0), radius: 2)
                .animation(.easeInOut(duration: 0.1), value: isActive)
                
                Rectangle()
                    .fill(theme.colors.divider)
                    .frame(width: holeSize * 1.1, height: circleStrokeWidth * 0.8)
                
                Group {
                    NoteHoleView(state: note.holesArray[3], size: holeSize, isActive: isActive, isSelfColored: colored)
                        .padding(.top, -circleStrokeWidth * 0.6)
                    NoteHoleView(state: note.holesArray[4], size: holeSize, isActive: isActive, isSelfColored: colored)
                    NoteHoleView(state: note.holesArray[5], size: holeSize, isActive: isActive, isSelfColored: colored)
                }
                .shadow(color: Color.orange.opacity((note == .VII && isActive) ? 1 : 0), radius: 2)
                .animation(.easeInOut(duration: 0.1), value: isActive)
                
                Group {
                    if colored && isActive {
                        Rectangle()
                            .fill(isActive ? .orange : theme.colors.closedHole)
                            .frame(width: circleStrokeWidth, height: holeSize)
                            .shadow(color: (isActive ? Color.orange : note.color).opacity(isActive ? 0.8 : 0.3), radius: isActive ? 4 : 2)
                            .animation(.easeInOut(duration: 0.1), value: isActive)
                            .overlay {
                                Rectangle()
                                    .fill(isActive ? .orange : theme.colors.closedHole)
                                    .frame(width: holeSize, height: circleStrokeWidth)
                                    .shadow(color: (isActive ? Color.orange : note.color).opacity(isActive ? 0.8 : 0.3), radius: isActive ? 4 : 2)
                                    .animation(.easeInOut(duration: 0.1), value: isActive)
                            }
                        
                    } else {
                        overblow(circleStrokeWidth: circleStrokeWidth, holeSize: holeSize)
                    }
                }
                .opacity(note.holesArray.count > 6 ? 1 : 0)
                .padding(.top, circleStrokeWidth * 0.3)
                
                if !colored {
                    Circle()
                        .fill(isActive ? .orange : note.color)
                        .frame(width: holeSize, height: holeSize)
                        .shadow(color: (isActive ? Color.orange : note.color).opacity(isActive ? 0.8 : 0.3), radius: isActive ? 4 : 2)
                        .animation(.easeInOut(duration: 0.1), value: isActive)
                        .padding(.top, circleStrokeWidth * 1.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    func overblow(circleStrokeWidth: CGFloat, holeSize: CGFloat) -> some View {
        Rectangle()
            .fill(theme.colors.closedHole)
            .frame(width: circleStrokeWidth, height: holeSize)
            .overlay {
                Rectangle()
                    .fill(theme.colors.closedHole)
                    .frame(width: holeSize, height: circleStrokeWidth)
            }
    }
}

#Preview {
    HStack(spacing: 20) {
        // Маленький размер
        ApplicatureView(note: .VII, isActive: true, colored: true)
            .frame(width: 40, height: 200)
//            .background(.red.opacity(0.2))
        
        // Средний размер
        ApplicatureView(note: .II2, isActive: true)
            .frame(width: 60, height: 300)
//            .background(.blue.opacity(0.2))
        
        // Большой размер
        ApplicatureView(note: .VI2, isActive: false)
            .frame(width: 100, height: 400)
//            .background(.green.opacity(0.2))
    }
    .padding()
    .background {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.06, blue: 0.1),
                Color(red: 0.1, green: 0.08, blue: 0.14),
                Color(red: 0.06, green: 0.06, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
