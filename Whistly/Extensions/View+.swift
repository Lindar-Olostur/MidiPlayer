import SwiftUI

extension View {
    func delayedAppearance(delay: TimeInterval) -> some View {
        modifier(DelayedAppearanceModifier(delay: delay))
    }
}

struct DelayedAppearanceModifier: ViewModifier {
    let delay: TimeInterval
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        Group {
            if isVisible {
                content
            } else {
                Color.clear
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                    )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                isVisible = true
            }
        }
    }
}

extension View {
    func rounded(_ radius: CGFloat? = nil) -> some View {
        let cornerRadius = radius ?? .infinity
        
        return self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    func circled() -> some View {
        return self
            .clipShape(.circle)
            .contentShape(.circle)
    }
    
    func roundCard(padding: CGFloat = 16, color: Color = .fillQuartenary, radius: CGFloat = 14) -> some View {
        return self
            .padding(padding)
            .background(color)
            .rounded(radius)
    }
    
    func roundButton(_ color: Color = .bgPrimary, _ size: CGFloat = 44) -> some View {
        self
            .frame(width: size, height: size)
            .background(color)
            .circled()
    }
}

#Preview(body: {
    Button {
    } label: {
        Text("refresh")
            .padding(16)
            .rounded()
    }

})

