import SwiftUI

struct PlaybackControlsSectionView: View {
    @Environment(MainContainer.self) private var viewModel

    var body: some View {
        HStack(spacing: 25) {
            ControlButton(systemName: "backward.end.fill", size: 20) {
                viewModel.sequencer.rewind()
                viewModel.scrollManager.scrollToStart()
            }

            ControlButton(systemName: "stop.fill", size: 20) {
                viewModel.sequencer.stop()
            }
            
            Button {
                viewModel.sequencer.onPlayPause()
            } label: {
                Circle()
                    .fill(
                        LinearGradient.primary
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .accentPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                    .overlay {
                        Image(systemName: viewModel.sequencer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .offset(x: viewModel.sequencer.isPlaying ? 0 : 2)
                    }
            }
            
            Button {
                viewModel.sequencer.isLooping.toggle()
            } label: {
                Circle()
                    .fill(viewModel.sequencer.isLooping
                          ? .accent.opacity(0.2)
                          : Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: viewModel.sequencer.isLooping ? "repeat.circle.fill" : "repeat")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.sequencer.isLooping ? .accent : .white.opacity(0.6))
                    }
            }
            
            ControlButton(systemName: "forward.end.fill", size: 20) {
                viewModel.sequencer.onNextMeasure()
            }
        }
        .padding(.bottom, 25)
    }
}

#Preview {
    PlaybackControlsSectionView()
    .environment(MainContainer())
}




















