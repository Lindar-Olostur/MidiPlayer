import ApphudSDK
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var router: NavigationManager
    enum OBScreen: Int, CaseIterable {
        case first, second, third
        
        var next: OBScreen? {
            let all = Self.allCases
            guard let index = all.firstIndex(of: self), index + 1 < all.count else {
                return nil
            }
            return all[index + 1]
        }
    }
    @State var isRestoring = false
    @State var obStep = OBScreen.first
    let titles = ["Easily learn tunes on the\ntin whistle", "It's genuinely useful and\nconvenient.", "Choose the mode that suits\nyou best."]
    let subtitles = ["Upload ABC tunes, and automatically\ngenerate fingerings for any key.", "Thousands of users are already playing\ntheir favorite tunes effortlessly.", "For any skill level, for any whistle,for any\nmelody."]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .center, spacing: 16) {
                    Group {
                        Text(titles[obStep.rawValue])
                            .font(.title)
                            .fixedSize()
                            .padding(.top, 4)
                        Text(subtitles[obStep.rawValue])
                            .font(.body)
                            .foregroundStyle(.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize()
                    
                    BigButton() {
                        withAnimation {
                            if let nextStep = obStep.next {
                                obStep = nextStep
                            } else {
                                router.onboardingFinished()
                            }
                        }
                    } label: {
                        Text("Continue").font(.body)
                            .foregroundStyle(.textPrimary)
                    }
                    OBFooterView(isRestoring: .constant(false))
            }
            .frame(maxWidth: UIDevice.isIPad ? 464 : .infinity)
            .padding(16)
            .background(.fillQuartenary)
            .clipShape(RoundedCorner(radius: 26, corners: [.topLeft, .topRight]))
        }
        .background {
            BackgroundView()
//            Group { TODO
//                switch obStep {
//                case .first: Image(".ob1")
//                        .resizable()
//                        .scaledToFill()
//                case .second:
//                    Image(".ob2")
//                        .resizable()
//                        .scaledToFill()
//                case .third:
//                    Image(".ob3")
//                        .resizable()
//                        .scaledToFill()
//                }
//            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(NavigationManager())
}

