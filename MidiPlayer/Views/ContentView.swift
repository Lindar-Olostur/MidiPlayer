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
    @State private var sequencer = MIDISequencer()
    @State private var sourceType: SourceType = .midi
    @State private var viewMode: ViewMode = .fingerChart
    @State private var whistleKey: WhistleKey = .D_high
    
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
            
            VStack(spacing: 14) {
                // Заголовок и переключатель источника
                headerSection
                
                // Выбор мелодии для ABC и строй вистла
                tuneAndWhistleSection
                
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
                positionInfoSection
                
                // Слайдер темпа и транспонирование
                tempoAndTransposeSection
                
                Spacer()
                
                // Кнопки управления
                playbackControlsSection
            }
        }
        .onAppear {
            loadSource(sourceType)
        }
        .onChange(of: sequencer.selectedTuneIndex) { _, _ in
            updateWhistleKeyFromTune()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whistly")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.7, green: 0.5, blue: 1.0),
                                Color(red: 0.4, green: 0.8, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if let tune = currentTuneName {
                    Text(tune)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Переключатель MIDI/ABC
            Picker("Source", selection: $sourceType) {
                ForEach(SourceType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .onChange(of: sourceType) { _, newValue in
                loadSource(newValue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var tuneAndWhistleSection: some View {
        HStack(spacing: 12) {
            //TODO доступные тональности мелодии под аппликатуры (при выборе меняют тональность на транспонировании и аппликатуры соответственно)
            
            ///промт
            ///А теперь хотелось бы попробовать реализовать основную киллер фичу приложения. В чем суть? Значит... Когда у нас тональность мелодии совпадает с тональностью висла, Ну, мы просчитываем Все ноты выводим аппликатуры. И как правило... У нас Каждой ноте соответствует определенная Картинка аппликатуры. То есть... Все ноты играбельны. В базовом варианте. Иногда бывает такое, что мы можем транспонировать мелодию в другую тональность Может, в параллельную, да? Или в соседнюю. И на том же самом висле мы можем сыграть ту же самую мелодию, но в другой тональности. И мне бы хотелось... Создать метод. который будет выводить Массив. Вот таких полностью играбельных тональностей, которые можно сыграть на одном висле.
            // Выбор строя вистла
            WhistleKeyPicker(whistleKey: $whistleKey)
            Spacer()
        }
        .padding(.horizontal, 20)
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
                    whistleKey: whistleKey
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
    
    private var positionInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Beat")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.1f", sequencer.currentBeat))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Measure")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(currentMeasure)/\(sequencer.totalMeasures)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Tempo")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(sequencer.tempo))")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
        .padding(.horizontal, 20)
    }
    
    private var tempoAndTransposeSection: some View {
        HStack(spacing: 20) {
            // Темп
            VStack(spacing: 4) {
                Text("Tempo")
                    .font(.caption2)
                    .foregroundColor(.gray)
                HStack {
                    Text("60")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Slider(value: $sequencer.tempo, in: 60...240, step: 1)
                        .tint(Color(red: 0.5, green: 0.6, blue: 0.9))
                    Text("240")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Транспонирование
            TransposeControl(
                transpose: $sequencer.transpose,
                originalKey: currentTuneKey
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var playbackControlsSection: some View {
        HStack(spacing: 25) {
            ControlButton(systemName: "backward.end.fill", size: 20) {
                sequencer.rewind()
            }
            
            ControlButton(systemName: "stop.fill", size: 20) {
                sequencer.stop()
            }
            
            // Play/Pause
            Button(action: {
                if sequencer.isPlaying {
                    sequencer.pause()
                } else {
                    sequencer.play()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: sequencer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .offset(x: sequencer.isPlaying ? 0 : 2)
                }
            }
            
            // Loop
            Button(action: {
                sequencer.isLooping.toggle()
            }) {
                ZStack {
                    Circle()
                        .fill(sequencer.isLooping
                              ? Color.cyan.opacity(0.2)
                              : Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: sequencer.isLooping ? "repeat.circle.fill" : "repeat")
                        .font(.system(size: 18))
                        .foregroundColor(sequencer.isLooping ? .cyan : .white.opacity(0.6))
                }
            }
            
            ControlButton(systemName: "forward.end.fill", size: 20) {
                let nextMeasureBeat = Double(currentMeasure * sequencer.beatsPerMeasure)
                if nextMeasureBeat < sequencer.endBeat {
                    sequencer.setPosition(nextMeasureBeat)
                }
            }
        }
        .padding(.bottom, 25)
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
        // Всегда используем KeyDetector для анализа нот (и для ABC, и для MIDI)
        if let midiInfo = sequencer.midiInfo {
            return KeyDetector.detectKey(from: midiInfo.allNotes)
        }
        return "C"
    }
    
    // MARK: - Methods
    
    private func loadSource(_ source: SourceType) {
        sequencer.stop()
        switch source {
        case .midi:
            sequencer.loadMIDIFile(named: "silverspear")
        case .abc:
            sequencer.loadABCFile(named: "ievanpolkka")//TODO 
        }
        // Устанавливаем строй вистла по тональности мелодии
        // TODO  updateWhistleKeyFromTune()
    }
    
    private func updateWhistleKeyFromTune() {
        whistleKey = WhistleKey.from(tuneKey: currentTuneKey)
    }
}

#Preview {
    ContentView()
}
