import SwiftUI

protocol AnimatedTab: CaseIterable, Hashable, RawRepresentable where RawValue == String {
    var title: String { get }
    var description: String { get }
}

struct CustomToggleView<T: AnimatedTab>: View {
    @Binding var selectedTab: T
    let spacing: CGFloat
    let bgColor: Color
    let buttonColor: Color
    let textColor: Color
    let radius: CGFloat
    let height: CGFloat
    let isComplesLabel: Bool
    
    init(
        selectedTab: Binding<T>,
        spacing: CGFloat = 0,
        bgColor: Color = .fillQuartenary,
        buttonColor: Color = .fillPrimary,
        textColor: Color = .textPrimary,
        radius: CGFloat = .infinity,
        height: CGFloat = 44,
        isComplesLabel: Bool = false
    ) {
        self._selectedTab = selectedTab
        self.spacing = spacing
        self.bgColor = bgColor
        self.buttonColor = buttonColor
        self.textColor = textColor
        self.radius = radius
        self.height = height
        self.isComplesLabel = isComplesLabel
    }
    
    var body: some View {
        ZStack {
            selectionIndicator
            HStack(spacing: spacing) {
                ForEach(Array(T.allCases), id: \.self) { tab in
                    Button {
                        withAnimation {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(alignment: .center, spacing: 4) {
                            Text(isComplesLabel ? tab.title : tab.rawValue)
                                .font(.body)
                                .multilineTextAlignment(.center)
                            if isComplesLabel {
                                Text(tab.description)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
//            .padding(.vertical, 16)
        }
        .frame(height: height)
        .background(bgColor)
        .rounded(radius)
    }
    
    private var selectionIndicator: some View {
        GeometryReader { geometry in
            let allCases = Array(T.allCases)
            let count = CGFloat(allCases.count)
            let totalSpacing = spacing * max(0, count - 1)
            let tabWidth = (geometry.size.width - totalSpacing) / count
            let selectedIndex = CGFloat(
                allCases.firstIndex(of: selectedTab) ?? 0
            )
            
            RoundedRectangle(cornerRadius: radius)
                .foregroundStyle(.accentPrimary)
                .frame(width: tabWidth)
                .offset(x: selectedIndex * (tabWidth + spacing))
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.7),
                    value: selectedTab
                )
        }
    }
}

#Preview {
    CustomToggleView(
        selectedTab: .constant(TestEnum.home),
                        spacing: 4,
        bgColor: .red, height: 66
                    )
}

enum TestEnum: String, AnimatedTab {
    case home
    case profile
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .profile:
            return "Profile"
        }
    }
    
    var description: String {
        switch self {
        case .home:
            return "Home"
        case .profile:
            return "Profile"
        }
    }
}
