import SwiftUI
import UniformTypeIdentifiers

enum SortOption: String, CaseIterable {
    case byName = "По названию"
    case byDate = "По дате"
    case byRating = "По оценке"
    
    var icon: String {
        switch self {
        case .byName: return "textformat.abc"
        case .byDate: return "calendar"
        case .byRating: return "star.fill"
        }
    }
}

struct TuneManagerView: View {
    @Environment(MainContainer.self) private var viewModel
    @Environment(\.dismiss) var dismiss
    @State private var showPicker = false
    @State private var importError: String?
    @State private var showError = false
    @State private var isLoading = false
    @State private var tuneToDelete: TuneModel?
    @State private var showDeleteConfirmation = false
    @State private var tuneToRename: TuneModel?
    @State private var showRenameDialog = false
    @State private var newTuneName = ""
    @State private var searchQuery = ""
    @State private var sortOption: SortOption = .byDate
    @State private var selectedTuneType: TuneType? = nil
    var onTuneImported: ((TuneModel) -> Void)?
    
    private var filteredTunes: [TuneModel] {
        var tunes: [TuneModel]
        if searchQuery.isEmpty {
            tunes = viewModel.storage.fetchAllTunes()
        } else {
            tunes = viewModel.storage.searchTunes(query: searchQuery)
        }
        
        if let selectedType = selectedTuneType {
            tunes = tunes.filter { $0.tuneType == selectedType }
        }
        
        switch sortOption {
        case .byName:
            return tunes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .byDate:
            return tunes.sorted { $0.effectiveDateModified > $1.effectiveDateModified }
        case .byRating:
            return tunes.sorted { $0.rating > $1.rating }
        }
    }
    
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
            
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)
                TextField("Поиск", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                Menu {
                    Button {
                        selectedTuneType = nil
                    } label: {
                        HStack {
                            Text("Все типы")
                            if selectedTuneType == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(TuneType.allCases, id: \.self) { type in
                        Button {
                            selectedTuneType = type
                        } label: {
                            HStack {
                                Text(type.rawValue)
                                if selectedTuneType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedTuneType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        if selectedTuneType != nil {
                            Text(selectedTuneType!.rawValue)
                                .lineLimit(1)
                                .font(.system(size: 12))
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 14))
                }
                
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sortOption.icon)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.fillSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ScrollView {
                if filteredTunes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.textTertiary)
                        Text(searchQuery.isEmpty ? "Нет мелодий" : "Ничего не найдено")
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(filteredTunes, id: \.id) { tune in
                        Button {
                            viewModel.storage.loadTune(tune, into: viewModel.sequencer)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Text(tune.title)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text(tune.tuneType == .unknown ? "" : tune.tuneType.rawValue)
                                Spacer()
                                Menu {
                                    Menu {
                                        ForEach(0...3, id: \.self) { rating in
                                            Button {
                                                viewModel.storage.updateTune(tune.id) { tune in
                                                    tune.rating = rating
                                                }
                                            } label: {
                                                HStack {
                                                    Text(String(repeating: "★", count: rating) + String(repeating: "☆", count: 3 - rating))
                                                    if tune.rating == rating {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text("Оценка")
                                            Image(systemName: "star.fill")
                                        }
                                    }
                                    
                                    Button {
                                        tuneToRename = tune
                                        newTuneName = tune.title
                                        showRenameDialog = true
                                    } label: {
                                        Text("Rename")
                                        Image(systemName: "abc")
                                            .foregroundColor(.red)
                                    }
                                    Button {
                                        tuneToDelete = tune
                                        showDeleteConfirmation = true
                                    } label: {
                                        Text("Delete")
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .contentShape(.capsule)
                                }
                            }
                            .roundCard()
                        }
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
        .alert("Переименовать мелодию", isPresented: $showRenameDialog) {
            TextField("Название", text: $newTuneName)
            Button("Отмена", role: .cancel) {
                tuneToRename = nil
                newTuneName = ""
            }
            Button("Сохранить") {
                if let tune = tuneToRename, !newTuneName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.storage.updateTune(tune.id) { tune in
                        tune.title = newTuneName.trimmingCharacters(in: .whitespaces)
                    }
                    if viewModel.storage.loadedTune?.id == tune.id {
                        viewModel.storage.updateLoadedTune { tune in
                            tune.title = newTuneName.trimmingCharacters(in: .whitespaces)
                        }
                    }
                    tuneToRename = nil
                    newTuneName = ""
                }
            }
        } message: {
            if let tune = tuneToRename {
                Text("Введите новое название для \"\(tune.title)\"")
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
