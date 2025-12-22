import SwiftUI
import StoreKit

struct MainView: View {
    @Environment(\.openURL) var openURL
    @Environment(MainContainer.self) private var viewModel
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert = true
    @AppStorage("shouldShowReviewAlert") private var shouldShowReviewAlert = true
    @State private var showAppStoreAlert = false
    @State private var shownAskReview = false
    @State private var triggerActionToReview = false
    
    
    
    @State private var openSettings: Bool = false
    @State private var openTuneManager = false
    @State private var viewMode: ViewMode = .fingerChart
    
    var body: some View {
        VStack(spacing: 16, content: {
            HStack {
                Text(viewModel.storage.loadedTune?.title ?? "Import any ABC")
                    .font(.headline).bold()
                    .lineLimit(1)
                    .truncationMode(.tail)
                Menu {
                    ForEach(TuneType.allCases, id: \.self) { type in
                        Button {
                            viewModel.storage.updateLoadedTune { tune in
                                tune.tuneType = type
                            }
                        } label: {
                            Text(type.rawValue)
                        }
                    }
                } label: {
                    Text(viewModel.storage.loadedTune?.tuneType.rawValue ?? "tune")
                        .font(.headline).bold()
                        .foregroundStyle(viewModel.storage.loadedTune?.tuneType == .unknown ? .textSecondary :  .white)
                }
                .disabled(viewModel.storage.loadedTune == nil)
                Spacer()
                Menu {
//                    Button { //TODO in settings
//                        // TODO Auth
//                    } label: {
//                        Text("Sign/Log in")
//                        Image(systemName: "person.circle")
//                    }
                    Button {
                        openTuneManager.toggle()
                    } label: {
                        Text("Load")
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        openSettings.toggle()
                    } label: {
                        Text("Settings")
                        Image(systemName: "gearshape.fill")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20))
                }
            }
            .padding(.vertical, 16)
            if viewModel.storage.loadedTune != nil {
                TuneAndWhistleSectionView()
            }
            NotesVizualizationView(viewMode: $viewMode)
            Spacer()
            PlaybackControlsSectionView()
        })
        .padding(.horizontal, 16)
        .background(BackgroundView())
        .onChange(of: triggerActionToReview, {
            if viewModel.premium.isSubscribed && shouldShowReviewAlert {
                shownAskReview.toggle()
            }
        })
        .alert("Do you like the app?", isPresented: $shownAskReview) {
            Button("No") {
                shouldShowReviewAlert = false
            }
            Button("Yes") {
                showAppStoreAlert = true
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("We Appreciate Your Feedback")
        }
        .alert("Please leave a review", isPresented: $showAppStoreAlert) {
            Button("Go to AppStore") {
                shouldShowReviewAlert = false
                openURL(URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!)
            }
        } message: {
            Text("Positive reviews are a powerful motivation for us to excel")
        }
        .fullScreenCover(isPresented: $openTuneManager) {
            TuneManagerView()
        }
        .fullScreenCover(isPresented: $openSettings) {
            SettingsView()
                .environment(viewModel.authService)
        }
        .onAppear {
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                viewModel.sequencer.startMeasure = 1
                viewModel.sequencer.endMeasure = 4
            })
            if let tune = viewModel.storage.tunesCache.first {
//            if let testTuneURL = Bundle.main.url(forResource: "testTune", withExtension: "abc"),
//               let tune = viewModel.storage.importFile(from: testTuneURL) {
                viewModel.storage.loadTune(tune, into: viewModel.sequencer)
            }
            #endif
        }
    }
}

#Preview {
    MainView()
        .environment(MainContainer())
}

