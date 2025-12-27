import SwiftUI

struct NotesVizualizationView: View {
    @Environment(MainContainer.self) private var viewModel
    @Binding var viewMode: ViewMode
    
    private var selectionIndicator: some View {
        GeometryReader { geometry in
            let allCases = Array(ViewMode.allCases)
            let count = CGFloat(allCases.count)
            let buttonWidth = (geometry.size.width) / count
            let selectedIndex = CGFloat(
                allCases.firstIndex(of: viewMode) ?? 0
            )
            
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient.primary)
                .frame(width: buttonWidth)
                .offset(x: selectedIndex * buttonWidth)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.7),
                    value: viewMode
                )
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.fillQuartenary)
                
                selectionIndicator
                
            HStack(spacing: 0) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                            withAnimation() {
                            viewMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 12))
                            
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(viewMode == mode ? .textPrimary : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            }
            .frame(width: 256, height: 44)
            if let midiInfo = viewModel.sequencer.midiInfo {
                Group {
                    switch viewMode {
                    case .pianoRoll:
                        PianoRollView(midiInfo: midiInfo)
                            .frame(height: 156)
                    case .fingerChart:
                        FingerChartView(midiInfo: midiInfo, whistleKey: viewModel.storage.loadedTune?.whistleKey ?? viewModel.userSettings.defaultWhistleKey)
                            .frame(height: 156)
                    }
                }
                .frame(height: 156)
                .background(Color.clear)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.fillQuartenary)
                    .frame(height: 156)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.textPrimary))
            }
        }
    }
}

#Preview {
    @Previewable @State var mode: ViewMode = ViewMode.pianoRoll
    NotesVizualizationView(viewMode: $mode)
        .environment(MainContainer())
}
