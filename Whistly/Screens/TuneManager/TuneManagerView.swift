import SwiftUI
import UniformTypeIdentifiers

struct TuneManagerView: View {
    @Environment(MainContainer.self) private var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var showPicker = false
    @State private var importError: String?
    @State private var showError = false
    @State private var isLoading = false
    @State private var tuneToDelete: TuneModel?
    @State private var showDeleteConfirmation = false
    var onTuneImported: ((TuneModel) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                }
                Spacer()
                Button {
                    showPicker.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 20))
                }
            }
            ScrollView {
            ForEach(viewModel.storage.fetchAllTunes(), id: \.id) { tune in
                HStack(spacing: 8) {
                    Text(tune.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(tune.tuneType == .unknown ? "" : tune.tuneType.rawValue)
                        Spacer()
                        Button {
                            tuneToDelete = tune
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                .onTapGesture {
                        viewModel.storage.loadTune(tune, into: viewModel.sequencer)
                    dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background {
            BackgroundView()
        }
        .alert("Удалить мелодию?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {
                tuneToDelete = nil
            }
            Button("Удалить", role: .destructive) {
                if let tune = tuneToDelete {
                    if viewModel.storage.loadedTune?.id == tune.id {
                        viewModel.storage.loadedTune = nil
                    }
                    viewModel.storage.deleteTune(tune.id)
                    tuneToDelete = nil
                }
            }
        } message: {
            if let tune = tuneToDelete {
                Text("Вы уверены, что хотите удалить \"\(tune.title)\"?")
            }
        }
#if os(iOS)
        .sheet(isPresented: $showPicker) {
            DocumentPicker(
                allowedContentTypes: [
                    UTType(filenameExtension: "abc") ?? .data
                ],
                onDocumentPicked: { url in
                    isLoading = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        let tune = viewModel.storage.importFile(from: url)
                        DispatchQueue.main.async {
                            isLoading = false
                            if let tune = tune {
                                viewModel.storage.loadTune(tune, into: viewModel.sequencer)
                                onTuneImported?(tune)
                                dismiss()
                            } else {
                                importError = "Can't load file"
                                showError = true
                            }
                        }
                    }
                }
            )
        }
#elseif os(macOS)
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [
                UTType(filenameExtension: "abc") ?? .data
            ],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                isLoading = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let tune = viewModel.storage.importFile(from: url)
                    DispatchQueue.main.async {
                        isLoading = false
                        if let tune = tune {
                            viewModel.storage.loadTune(tune, into: viewModel.sequencer)
                            onTuneImported?(tune)
                            dismiss()
                        } else {
                            importError = "Can't load file"
                            showError = true
                        }
                    }
                }
            case .failure:
                importError = "Can't open file"
                showError = true
            }
        }
    #endif
    }
}

#Preview {
    TuneManagerView()
        .environment(MainContainer())
}
