//
//  ContentView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 27.11.2025.
//

import SwiftUI

// MARK: - Enums

enum SourceType: String, CaseIterable, Codable {
    case midi = "MIDI"
    case abc = "ABC"
}

enum ViewMode: String, CaseIterable {
    case pianoRoll = "Piano Roll"
    case fingerChart = "Fingering"
    
    var icon: String {
        switch self {
        case .pianoRoll: return "pianokeys"
        case .fingerChart: return "hand.raised.fingers.spread"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var orientation = OrientationService()
    @State private var sequencer = MIDISequencer()
    @State private var sourceType: SourceType = .midi
    @State private var viewMode: ViewMode = .fingerChart
    @State private var whistleKey: WhistleKey = .D_high
    @State private var playableKeyVariants: [WhistleConverter.PlayableKeyVariant] = []
    @State private var playableKeys: [String] = []
    @StateObject private var tuneManager = TuneManager()
    @StateObject private var appSettings = AppSettings()
    @State private var showFileImport = false
    @State private var currentTuneId: UUID?
    
    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.14),
                    Color(red: 0.06, green: 0.06, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            if orientation.currentOrientation == .portrait {
                portrait
            } else {
                landscape
            }
        }
        .onAppear {
            // Загружаем последнюю мелодию или дефолтную
            if let lastTune = tuneManager.tunes.last {
                loadTune(lastTune)
            } else {
                loadSource(sourceType)
            }
            orientation.setupOrientationObserver()
            AppDelegate.orientationLock = .all
        }
        .onDisappear {
            orientation.removeOrientationObserver()
            AppDelegate.orientationLock = .portrait
        }
        .onChange(of: sequencer.selectedTuneIndex) { _, _ in
            updateWhistleKeyFromTune()
        }
        .onChange(of: whistleKey) { _, _ in
            let updatedKeys = updatePlayableKeys()
            // Автоматически выбираем первую тональность из списка playable keys
            if let firstKey = updatedKeys.first {
                selectKey(firstKey)
            } else {
                optimizeOctaveForCurrentTune()
            }
            saveCurrentSettings()
        }
        .onChange(of: sequencer.transpose) { _, _ in
            saveCurrentSettings()
        }
        .onChange(of: sequencer.tempo) { _, _ in
            saveCurrentSettings()
        }
        .onChange(of: sequencer.startMeasure) { _, _ in
            saveCurrentSettings()
        }
        .onChange(of: sequencer.endMeasure) { _, _ in
            saveCurrentSettings()
        }
        .sheet(isPresented: $showFileImport) {
            FileImportView(tuneManager: tuneManager) { tune in
                loadNewImportedTune(tune)
            }
        }
    }
    
    @ViewBuilder
    private var landscape: some View {
        Color.clear.ignoresSafeArea()
            .overlay {
                visualizationSection
                    .ignoresSafeArea(edges: .leading)
            }
            .overlay(alignment: .bottom) {
                if !sequencer.isPlaying {
                    playbackControlsSection
                        .transition(.move(edge: .bottom))
                }
            }
            .onTapGesture {
                withAnimation { sequencer.pause() }
            }
    }
    
    @ViewBuilder
    private var portrait: some View {
            VStack(spacing: 14) {
                // Заголовок и переключатель источника
            HeaderSectionView(
                tuneName: currentTuneName,
                sourceType: $sourceType,
                onSourceChange: loadSource,
                onImportTap: {
                    showFileImport = true
                }
            )
                
                // Выбор мелодии для ABC и строй вистла
            TuneAndWhistleSectionView(
                whistleKey: $whistleKey,
                playableKeys: playableKeys,
                viewMode: viewMode,
                currentTuneKey: currentTuneKey,
                currentDisplayedKey: currentDisplayedKey,
                onKeySelect: selectKey
            )
                
                // Переключатель режима отображения
                ViewModePicker(viewMode: $viewMode)
                    .padding(.horizontal, 20)
                
                // Piano Roll или Аппликатуры
                visualizationSection
                
                // Выбор диапазона тактов
                MeasureSelectorView(
                    startMeasure: $sequencer.startMeasure,
                    endMeasure: $sequencer.endMeasure,
                    totalMeasures: sequencer.totalMeasures
                )
                .padding(.horizontal, 20)
                
                // Информация о позиции
            PositionInfoSectionView(
                currentBeat: sequencer.currentBeat,
                currentMeasure: currentMeasure,
                totalMeasures: sequencer.totalMeasures,
                tempo: sequencer.tempo
            )
                
                // Слайдер темпа
            TempoAndTransposeSectionView(
                tempo: $sequencer.tempo
            )
                
                Spacer()
                
                // Кнопки управления
                playbackControlsSection
        }
    }
    
    @ViewBuilder
    private var playbackControlsSection: some View {
        PlaybackControlsSectionView(
            isPlaying: sequencer.isPlaying,
            isLooping: sequencer.isLooping,
            currentMeasure: currentMeasure,
            beatsPerMeasure: sequencer.beatsPerMeasure,
            endBeat: sequencer.endBeat,
            onRewind: { sequencer.rewind() },
            onStop: { sequencer.stop() },
            onPlayPause: {
                if sequencer.isPlaying {
                    withAnimation { sequencer.pause() }
                } else {
                    withAnimation { sequencer.play() }
                }
            },
            onToggleLoop: { sequencer.isLooping.toggle() },
            onNextMeasure: {
                let nextMeasureBeat = Double(currentMeasure * sequencer.beatsPerMeasure)
                if nextMeasureBeat < sequencer.endBeat {
                    sequencer.setPosition(nextMeasureBeat)
                }
            }
        )
    }
    
    // MARK: - View Sections
    
    /// Выбор тональности из списка playable тональностей
    private func selectKey(_ key: String) {
        // Находим вариант для выбранной тональности
        if let variant = playableKeyVariants.first(where: { $0.key == key }) {
            sequencer.transpose = variant.transpose
            print("🎵 Выбрана тональность \(key) с транспонированием \(variant.transpose > 0 ? "+" : "")\(variant.transpose) (диапазон от \(variant.melodyMin))")
        } else {
            // Fallback на старую логику, если вариант не найден
            guard let originalInfo = sequencer.originalTuneInfo else { return }
            sequencer.transpose = KeyCalculator.optimalTranspose(
                from: currentTuneKey,
                to: key,
                notes: originalInfo.allNotes,
                whistleKey: whistleKey
            )
            print("⚠️ Вариант не найден, использован optimalTranspose")
        }
        saveCurrentSettings()
    }

    /// Текущая отображаемая тональность (с учётом транспонирования)
    private var currentDisplayedKey: String {
        KeyCalculator.currentDisplayedKey(baseKey: currentTuneKey, transpose: sequencer.transpose)
    }
    
    @ViewBuilder
    private var visualizationSection: some View {
        if let midiInfo = sequencer.midiInfo {
            switch viewMode {
            case .pianoRoll:
                PianoRollView(
                    midiInfo: midiInfo,
                    currentBeat: sequencer.currentBeat,
                    startMeasure: sequencer.startMeasure,
                    endMeasure: sequencer.endMeasure,
                    isPlaying: sequencer.isPlaying
                )
                .frame(height: 220)
                .padding(.horizontal, 12)
                
            case .fingerChart:
                FingerChartView(
                    midiInfo: midiInfo,
                    currentBeat: sequencer.currentBeat,
                    startMeasure: sequencer.startMeasure,
                    endMeasure: sequencer.endMeasure,
                    isPlaying: sequencer.isPlaying,
                    whistleKey: whistleKey,
                    mode: orientation.isPortrait ? .portrait : .landscape
                )
                .frame(height: 220)
                .padding(.horizontal, 12)
            }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .frame(height: 220)
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
                .padding(.horizontal, 12)
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var currentMeasure: Int {
        guard sequencer.midiInfo != nil else { return 1 }
        return Int(sequencer.currentBeat / Double(sequencer.beatsPerMeasure)) + 1
    }
    
    private var currentTuneName: String? {
        // Если есть загруженная мелодия из файла, используем её название
        if let tuneId = currentTuneId, let tune = tuneManager.tunes.first(where: { $0.id == tuneId }) {
            return tune.title ?? tune.originalFileName
        }
        
        // Иначе используем старую логику для bundle файлов
        if sourceType == .abc && !sequencer.abcTunes.isEmpty {
            return sequencer.abcTunes[sequencer.selectedTuneIndex].title
        } else if sourceType == .midi {
            return "Silver Spear (MIDI)"
        }
        return nil
    }
    
    private var currentTuneKey: String {
        // Определяем тональность по оригинальным нотам (до транспонирования)
        if let originalInfo = sequencer.originalTuneInfo {
            // Для MIDI используем оригинальные ноты
            return KeyDetector.detectKey(from: originalInfo.allNotes)
        } else if let midiInfo = sequencer.midiInfo, sequencer.abcTunes.isEmpty {
            // Для MIDI без оригинальных данных (старый код)
            return KeyDetector.detectKey(from: midiInfo.allNotes)
        } else if !sequencer.abcTunes.isEmpty {
            // Для ABC мелодий используем ключ из файла (если есть) или анализируем
            if let firstTune = sequencer.abcTunes.first, !firstTune.key.isEmpty {
                return firstTune.key
            } else if let midiInfo = sequencer.midiInfo {
                return KeyDetector.detectKey(from: midiInfo.allNotes)
            }
        }
        return "C"
    }
    
    // MARK: - Methods
    
    /// Загружает новую импортированную мелодию с автоматическим транспонированием в C4
    private func loadNewImportedTune(_ tune: TuneModel) {
        // Загружаем БЕЗ установки currentTuneId, чтобы применить автотранспонирование
        sourceType = tune.fileType
        sequencer.stop()
        
        // Загружаем файл
        let fileURL = tuneManager.fileURL(for: tune)
        if tune.fileType == .midi {
            sequencer.loadMIDIFile(url: fileURL)
        } else {
            sequencer.loadABCFile(url: fileURL)
            sequencer.selectedTuneIndex = tune.selectedTuneIndex
        }
        
        // Устанавливаем строй вистла и применяем транспонирование в C4
        whistleKey = WhistleKey.from(tuneKey: currentTuneKey)
        updatePlayableKeys()
        transposeToOctave4()
        
        // Сохраняем настройки с новым транспонированием
        tuneManager.saveSettings(
            for: tune.id,
            transpose: sequencer.transpose,
            tempo: sequencer.tempo,
            whistleKey: whistleKey,
            selectedKey: playableKeyVariants.first(where: { $0.transpose == sequencer.transpose })?.key,
            startMeasure: sequencer.startMeasure,
            endMeasure: sequencer.endMeasure,
            selectedTuneIndex: sequencer.selectedTuneIndex
        )
        
        // Теперь устанавливаем currentTuneId
        currentTuneId = tune.id
    }
    
    /// Загружает мелодию из TuneModel (для сохраненных мелодий)
    private func loadTune(_ tune: TuneModel) {
        currentTuneId = tune.id
        sourceType = tune.fileType
        sequencer.stop()
        
        // Восстанавливаем настройки
        sequencer.transpose = tune.transpose
        sequencer.tempo = tune.tempo
        whistleKey = tune.whistleKey
        sequencer.startMeasure = tune.startMeasure
        sequencer.endMeasure = tune.endMeasure
        
        // Загружаем файл
        let fileURL = tuneManager.fileURL(for: tune)
        if tune.fileType == .midi {
            sequencer.loadMIDIFile(url: fileURL)
        } else {
            sequencer.loadABCFile(url: fileURL)
            sequencer.selectedTuneIndex = tune.selectedTuneIndex
        }
        
        // Устанавливаем строй вистла по тональности мелодии
        // Для сохраненных мелодий не применяем автотранспонирование
        updateWhistleKeyFromTune(applyAutoTranspose: false)
        
        // Восстанавливаем выбранную тональность если есть
        if let selectedKey = tune.selectedKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectKey(selectedKey)
            }
        }
    }
    
    /// Сохраняет текущие настройки мелодии
    private func saveCurrentSettings() {
        guard let tuneId = currentTuneId else { return }
        
        tuneManager.saveSettings(
            for: tuneId,
            transpose: sequencer.transpose,
            tempo: sequencer.tempo,
            whistleKey: whistleKey,
            selectedKey: playableKeyVariants.first(where: { $0.transpose == sequencer.transpose })?.key,
            startMeasure: sequencer.startMeasure,
            endMeasure: sequencer.endMeasure,
            selectedTuneIndex: sequencer.selectedTuneIndex
        )
    }
    
    private func loadSource(_ source: SourceType) {
        // sourceType уже установлен через binding в HeaderSectionView
        sequencer.stop()
        currentTuneId = nil
        
        // Сбрасываем транспонирование при переключении источника
        sequencer.transpose = 0
        
        switch source {
        case .midi:
            sequencer.loadMIDIFile(named: "silverspear")
        case .abc:
            sequencer.loadABCFile(named: "ievanpolkka")//TODO
        }
        // Устанавливаем строй вистла по тональности мелодии
        updateWhistleKeyFromTune()
    }
    
    private func updateWhistleKeyFromTune(applyAutoTranspose: Bool = true) {
        whistleKey = WhistleKey.from(tuneKey: currentTuneKey)
        updatePlayableKeys()
        
        // Если это новая мелодия (не сохраненная), транспонируем в тонику на 4 октаву
        if currentTuneId == nil && applyAutoTranspose {
            transposeToOctave4()
        } else if currentTuneId == nil {
            // Для новых мелодий без автотранспонирования используем оптимальную октаву
            optimizeOctaveForCurrentTune()
        }
        // Для сохраненных мелодий (currentTuneId != nil) не меняем транспонирование
    }
    
    /// Транспонирует мелодию так, чтобы тоника была на 4 октаве (C4)
    private func transposeToOctave4() {
        guard let originalInfo = sequencer.originalTuneInfo else { return }
        
        let transpose = KeyCalculator.transposeToOctave4(
            key: currentTuneKey,
            notes: originalInfo.allNotes
        )
        
        sequencer.transpose = transpose
        print("🎵 Автоматически транспонировано в тонику на 4 октаву: \(transpose > 0 ? "+" : "")\(transpose) полутонов")
    }

    /// Оптимизирует октаву для текущей мелодии и выбранного свистля
    private func optimizeOctaveForCurrentTune() {
        guard let originalInfo = sequencer.originalTuneInfo else { return }

        // Оптимизируем октаву для текущей тональности (без смены тональности)
        let optimalTranspose = KeyCalculator.optimalTranspose(
            from: currentTuneKey,
            to: currentTuneKey,  // та же тональность
            notes: originalInfo.allNotes,
            whistleKey: whistleKey
        )

        // Устанавливаем оптимальную октаву
        sequencer.transpose = optimalTranspose
    }

    @discardableResult
    private func updatePlayableKeys() -> [String] {
        guard let originalInfo = sequencer.originalTuneInfo else {
            playableKeys = []
            playableKeyVariants = []
            return []
        }
        let variants = WhistleConverter.findPlayableKeyVariants(
            for: originalInfo.allNotes,
            whistleKey: whistleKey,
            baseKey: currentTuneKey
        )
        playableKeyVariants = variants
        playableKeys = variants.map { $0.key }
        return playableKeys
    }
}

#Preview {
    ContentView()
}
