//
//  ContentView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 27.11.2025.
//

import SwiftUI

// MARK: - Enums

enum SourceType: String, CaseIterable {
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
    @State private var playableKeys: [String] = []
    
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
            loadSource(sourceType)
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
            updatePlayableKeys()
            // Оптимизируем октаву при смене свистля, если пользователь не менял настройки
            if sequencer.transpose == 0 {
                optimizeOctaveForCurrentTune()
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
                onSourceChange: loadSource
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
                
                // Слайдер темпа и транспонирование
            TempoAndTransposeSectionView(
                tempo: $sequencer.tempo,
                transpose: $sequencer.transpose,
                originalKey: currentTuneKey
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
        guard let originalInfo = sequencer.originalTuneInfo else { return }
        sequencer.transpose = KeyCalculator.optimalTranspose(
            from: currentTuneKey,
            to: key,
            notes: originalInfo.allNotes,
            whistleKey: whistleKey
        )
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
    
    private func loadSource(_ source: SourceType) {
        // sourceType уже установлен через binding в HeaderSectionView
        sequencer.stop()
        switch source {
        case .midi:
            sequencer.loadMIDIFile(named: "silverspear")
        case .abc:
            sequencer.loadABCFile(named: "ievanpolkka")//TODO
        }
        // Устанавливаем строй вистла по тональности мелодии
        updateWhistleKeyFromTune()
    }
    
    private func updateWhistleKeyFromTune() {
        whistleKey = WhistleKey.from(tuneKey: currentTuneKey)
        updatePlayableKeys()
        optimizeOctaveForCurrentTune()
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

        // Устанавливаем оптимальную октаву только если текущий transpose = 0
        // (т.е. если пользователь еще не менял настройки вручную)
        if sequencer.transpose == 0 {
            sequencer.transpose = optimalTranspose
        }
    }

    private func updatePlayableKeys() {
        guard let originalInfo = sequencer.originalTuneInfo else { return }
        playableKeys = WhistleConverter.findPlayableKeys(
            for: originalInfo.allNotes,
            whistleKey: whistleKey,
            baseKey: currentTuneKey
        )
    }
}

#Preview {
    ContentView()
}
