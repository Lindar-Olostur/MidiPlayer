import SwiftUI

struct BigButton<Content: View>: View {
    var width: CGFloat
    var height: CGFloat
    var color: Color?
    var corners: CGFloat
    var padding: CGFloat
    let action: () -> Void
    let label: Content
    
    init(width: CGFloat = .infinity, height: CGFloat = 60, color: Color? = nil, corners: CGFloat = 30, padding: CGFloat = 0, action: @escaping () -> Void, label: () -> Content) {
        self.width = width
        self.height = height
        self.color = color
        self.corners = corners
        self.padding = padding
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            label
                .frame(maxWidth: width, minHeight: height)
                .background(color == nil ? LinearGradient.primary : LinearGradient.linearGradient(colors: [color!], startPoint: .top, endPoint: .bottom))
                .cornerRadius(corners)
                .padding(padding)
                .contentShape(Rectangle())
        }
    }
}

#Preview {
    BigButton(width: .infinity, height: 56, color: .red, corners: 20, padding: 0) { } label: {
        Text("LOL").foregroundStyle(.white)
    }
}

