
import SwiftUI

class FingerChartStyleManager: ObservableObject {
    @Published var colors: ChartScheme = .darkAdaptive
    
    // Коэффициенты для адаптивных размеров (относительно размера родителя)
    @Published var holeSizeCoefficient: CGFloat = 0.15  // Размер отверстия относительно ширины
    @Published var lineWidthCoefficient: CGFloat = 0.08  // Толщина линий относительно ширины
    @Published var holeSpacingCoefficient: CGFloat = 0.14  // Расстояние между отверстиями относительно ширины
    @Published var lineHeightCoefficient: CGFloat = 0.08  // Высота горизонтальной линии относительно ширины
    @Published var octaveLineWidthCoefficient: CGFloat = 0.08  // Толщина вертикальной линии октавы относительно ширины
    
    // Минимальные значения для очень маленьких размеров
    @Published var minHoleSize: CGFloat = 8
    @Published var minLineWidth: CGFloat = 1
    @Published var minHoleSpacing: CGFloat = 4
    
    static let shared = FingerChartStyleManager()
    
    // Вычисляемые свойства для обратной совместимости (можно использовать для фиксированных размеров)
    var lines: CGFloat { 10 }  // Для обратной совместимости
    var holeSpacing: CGFloat { 24 }  // Для обратной совместимости
    
    enum ChartScheme: CaseIterable {
        case simpleBlackAndWhite
        case simpleInversed
        case darkAdaptive
        
        var divider: Color {
            switch self {
            case .simpleBlackAndWhite: .black
            case .simpleInversed: .white
            case .darkAdaptive: .white.opacity(0.4)
            }
        }
        
        var holeStroke: Color {
            switch self {
            case .simpleBlackAndWhite: .black
            case .simpleInversed: .clear
            case .darkAdaptive: .white.opacity(0.05)
            }
        }
        
        var openHole: Color {
            switch self {
            case .simpleBlackAndWhite: .white
            case .simpleInversed: .black
            case .darkAdaptive: .white.opacity(0.15)
            }
        }
        
        var halfClosedHole: Color {
            switch self {
            case .simpleBlackAndWhite: .black
            case .simpleInversed: .white
            case .darkAdaptive: .purple
            }
        }
        
        var closedHole: Color {
            switch self {
            case .simpleBlackAndWhite: .black
            case .simpleInversed: .white
            case .darkAdaptive: .purple
            }
        }
    }
}
