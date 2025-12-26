import Foundation
import Observation

struct TuneModel: Identifiable, Codable {
    let id: String
    var abcContent: String
    let dateAdded: Date
    
    var transpose: Int = 0
    var tempo: Double = 120
    var whistleKey: WhistleKey = .D
    var selectedKey: String?
    
    var startMeasure: Int = 1
    var endMeasure: Int = 1
    
    var selectedTuneIndex: Int = 0
    
    var measureLoops: [MeasureLoop] = []
    var selectedLoopId: UUID?
    
    var title: String = "Unknown"
    var detectedKey: String?
    
    var tuneType: TuneType = .unknown
}

@Observable
final class TuneStoreManager {
    private let cacheURL: URL
    var tunesCache: [TuneModel] = []
    var loadedTune: TuneModel?
    var isLoading = false
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheURL = documentsPath.appendingPathComponent("tunes_cache.json")
        tunesCache = fetchAllTunes()
    }
    
    
    
    func fetchAllTunes() -> [TuneModel] {
        if !tunesCache.isEmpty {
            return tunesCache
        }
        return loadTunes()
    }
    
    func getTune(by id: String) -> TuneModel? {
        return fetchAllTunes().first { $0.id == id }
    }
    
    func saveTune(_ tune: TuneModel) {
        var tunes = fetchAllTunes()
        if let index = tunes.firstIndex(where: { $0.id == tune.id }) {
            tunes[index] = tune
        } else {
            tunes.append(tune)
        }
        saveTunes(tunes)
        tunesCache = tunes
    }
    
    func deleteTune(_ tuneId: String) {
        var tunes = fetchAllTunes()
        tunes.removeAll { $0.id == tuneId }
        saveTunes(tunes)
        tunesCache = tunes
    }
    
    func updateTune(_ tuneId: String, update: (inout TuneModel) -> Void) {
        guard var tune = getTune(by: tuneId) else { return }
        update(&tune)
        saveTune(tune)
    }
    
    func updateLoadedTune(_ update: (inout TuneModel) -> Void) {
        guard var tune = loadedTune else { return }
        update(&tune)
        loadedTune = tune
        saveTune(tune)
    }
    
    func searchTunes(query: String) -> [TuneModel] {
        let tunes = fetchAllTunes()
        guard !query.isEmpty else { return tunes }
        
        let lowerQuery = query.lowercased()
        return tunes.filter { tune in
            (tune.title.lowercased().contains(lowerQuery)) ||
            (tune.detectedKey?.lowercased().contains(lowerQuery) ?? false)
        }
    }
    
    func fetchTunes(limit: Int, offset: Int = 0) -> [TuneModel] {
        let allTunes = fetchAllTunes()
        guard offset < allTunes.count else { return [] }
        let endIndex = min(offset + limit, allTunes.count)
        return Array(allTunes[offset..<endIndex])
    }
    
    func count() -> Int {
        return fetchAllTunes().count
    }
    
    func invalidateCache() {
        tunesCache = []
    }
    
    func clearAll() {
        tunesCache = []
        saveTunes([])
    }
    
    func importFile(from url: URL) -> TuneModel? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let abcContent = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        
        let metadata = ABCParser.extractMetadata(from: abcContent)
        let title = metadata["T"]?.isEmpty == false ? metadata["T"]! : url.deletingPathExtension().lastPathComponent
        let detectedKey = metadata["K"]?.isEmpty == false ? metadata["K"] : nil
        
        let tune = TuneModel(
            id: UUID().uuidString,
            abcContent: abcContent,
            dateAdded: Date(),
            title: title,
            detectedKey: detectedKey
        )
        
        saveTune(tune)
        return tune
    }
    
    func loadTune(_ tune: TuneModel, into sequencer: MIDISequencer) {
        isLoading = true
        loadedTune = tune
        
        sequencer.stop()
        
        let savedWhistleKey = tune.whistleKey
        let savedTranspose = tune.transpose
        let savedSelectedKey = tune.selectedKey
        let savedLoops = tune.measureLoops
        let savedSelectedLoopId = tune.selectedLoopId
        
        sequencer.tempo = tune.tempo
        sequencer.startMeasure = tune.startMeasure
        sequencer.endMeasure = tune.endMeasure
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(tune.id).abc")
            
            // Удаляем старый временный файл, если существует
            try? FileManager.default.removeItem(at: tempURL)
            
            do {
                try tune.abcContent.write(to: tempURL, atomically: true, encoding: .utf8)
                
                sequencer.loadABCFile(url: tempURL)
                sequencer.selectedTuneIndex = tune.selectedTuneIndex
                
                DispatchQueue.main.async {
                    if tune.measureLoops.isEmpty {
                        let totalMeasures = sequencer.totalMeasures
                        let beatsPerMeasure = sequencer.beatsPerMeasure
                        let defaultLoops = MeasureLoop.generateDefaultLoops(
                            totalMeasures: totalMeasures,
                            beatsPerMeasure: beatsPerMeasure
                        )
                        
                        var updatedTune = tune
                        updatedTune.measureLoops = defaultLoops
                        updatedTune.selectedLoopId = defaultLoops.first?.id
                        self.saveTune(updatedTune)
                        self.loadedTune = updatedTune
                        
                        if let selectedLoopId = updatedTune.selectedLoopId,
                           let selectedLoop = updatedTune.measureLoops.first(where: { $0.id == selectedLoopId }) {
                            sequencer.startMeasure = selectedLoop.startMeasure
                            sequencer.endMeasure = min(selectedLoop.endMeasure, sequencer.totalMeasures)
                        }
                    } else {
                        if let selectedLoopId = savedSelectedLoopId,
                           let selectedLoop = savedLoops.first(where: { $0.id == selectedLoopId }) {
                            sequencer.startMeasure = selectedLoop.startMeasure
                            sequencer.endMeasure = min(selectedLoop.endMeasure, sequencer.totalMeasures)
                        } else {
                            sequencer.startMeasure = tune.startMeasure
                            sequencer.endMeasure = tune.endMeasure
                        }
                    }
                    
                    sequencer.transpose = savedTranspose
                    
                    self.isLoading = false
                    
                    // Удаляем временный файл после использования
                    try? FileManager.default.removeItem(at: tempURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Failed to create temporary file: \(error)")
                }
                // Удаляем временный файл даже при ошибке
                try? FileManager.default.removeItem(at: tempURL)
            }
        }
    }
    
    private func loadTunes() -> [TuneModel] {
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL),
              let tunes = try? decodeTunes(from: data) else {
            print("📁 No saved tunes found, starting fresh")
            tunesCache = []
            return []
        }
        
        print("📁 Loaded \(tunes.count) tunes from storage")
        tunesCache = tunes
        return tunes
    }
    
    private func saveTunes(_ tunes: [TuneModel]) {
        guard let data = try? encodeTunes(tunes) else {
            print("❌ Failed to encode tunes")
            return
        }
        
        do {
            try data.write(to: cacheURL)
            print("💾 Saved \(tunes.count) tunes to storage")
        } catch {
            print("❌ Failed to save tunes: \(error)")
        }
    }
    
    private func encodeTunes(_ tunes: [TuneModel]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(tunes)
    }
    
    private func decodeTunes(from data: Data) throws -> [TuneModel] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode([TuneModel].self, from: data)
    }
}
