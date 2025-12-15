import SwiftUI

struct PurchasesToggle: View {
    @Binding var toggle: Bool
    let tintColor: Color
    let bgColor: Color
    let scale: CGFloat
    let textColor: Color
    let offColor: Color
    let text: String
    let corners: CGFloat
    var height: CGFloat
    var width: CGFloat
    
    public init(toggle: Binding<Bool>, tintColor: Color, bgColor: Color, scale: CGFloat = 1, textColor: Color, offColor: Color, text: String, corners: CGFloat, height: CGFloat, width: CGFloat = .infinity) {
        self._toggle = toggle
        self.tintColor = tintColor
        self.bgColor = bgColor
        self.scale = scale
        self.textColor = textColor
        self.offColor = offColor
        self.text = text
        self.corners = corners
        self.height = height
        self.width = width
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
            Spacer()
            Toggle("", isOn: $toggle)
                .labelsHidden()
                .scaleEffect(scale)
                .toggleStyle(ColoredToggleStyle(onColor: tintColor, offColor: offColor))
        }
        .padding(16)
        .frame(maxWidth: width, maxHeight: height)
        .background(bgColor)
        .cornerRadius(corners)
    }
}

#Preview {
    PurchasesToggle(toggle: .constant(false), tintColor: .red, bgColor: .gray.opacity(0.2), textColor: .black, offColor: .blue, text: "Merge into one DF file", corners: 30, height: 56)
}

struct ColoredToggleStyle: ToggleStyle {
    var onColor = Color(UIColor.green)
    var offColor = Color(UIColor.systemGray5)
    var thumbColor = Color.white
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(spacing: 0) {
            Button(action: {
                feedbackGenerator.impactOccurred()
                configuration.isOn.toggle()
            } ) {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 64, height: 28)
                    .overlay(
                        Capsule()
                            .fill(thumbColor)
                            .frame(width: 39, height: 24)
                            .shadow(radius: 1, x: 1, y: 1)
                            .padding(1.5)
                            .offset(x: configuration.isOn ? 10 : -10))
                    .animation(Animation.easeInOut(duration: 0.1))
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

