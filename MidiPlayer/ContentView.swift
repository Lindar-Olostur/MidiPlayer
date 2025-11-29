//
//  ContentView.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 27.11.2025.
//

import SwiftUI

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

struct ContentView: View {
    @State private var sequencer = MIDISequencer()
    @State private var sourceType: SourceType = .abc
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
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MIDI Sequencer")
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
                
                // Выбор мелодии для ABC и строй вистла
                HStack(spacing: 12) {
                    if sourceType == .abc && !sequencer.abcTunes.isEmpty {
                        TuneSelectorView(
                            tunes: sequencer.abcTunes,
                            selectedIndex: $sequencer.selectedTuneIndex,
                            onSelect: { index in
                                sequencer.stop()
                                sequencer.loadTune(at: index)
                            }
                        )
                    }
                    
                    Spacer()
                    
                    // Выбор строя вистла
                    WhistleKeyPicker(whistleKey: $whistleKey)
                }
                .padding(.horizontal, 20)
                
                // Переключатель режима отображения
                ViewModePicker(viewMode: $viewMode)
                    .padding(.horizontal, 20)
                
                // Piano Roll или Аппликатуры
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
                            tuneKey: currentTuneKey
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
                
                // Выбор диапазона тактов
                MeasureSelectorView(
                    startMeasure: $sequencer.startMeasure,
                    endMeasure: $sequencer.endMeasure,
                    totalMeasures: sequencer.totalMeasures
                )
                .padding(.horizontal, 20)
                
                // Информация о позиции
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
                
                // Слайдер темпа и транспонирование
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
                
                Spacer()
                
                // Кнопки управления
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
        }
        .onAppear {
            loadSource(sourceType)
        }
        .onChange(of: sequencer.selectedTuneIndex) { _, _ in
            updateWhistleKeyFromTune()
        }
    }
    
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
        if sourceType == .abc && !sequencer.abcTunes.isEmpty {
            return sequencer.abcTunes[sequencer.selectedTuneIndex].key
        }
        return "D"
    }
    
    private func loadSource(_ source: SourceType) {
        sequencer.stop()
        switch source {
        case .midi:
            sequencer.loadMIDIFile(named: "silverspear")
        case .abc:
            sequencer.loadABCFile(named: "silverspear")
        }
        // Устанавливаем строй вистла по тональности мелодии
        updateWhistleKeyFromTune()
    }
    
    private func updateWhistleKeyFromTune() {
        let key = currentTuneKey
        whistleKey = whistleKeyFromTuneKey(key)
    }
    
    /// Преобразует тональность мелодии в строй вистла
    private func whistleKeyFromTuneKey(_ tuneKey: String) -> WhistleKey {
        let key = tuneKey.trimmingCharacters(in: .whitespaces).uppercased()
        
        // Извлекаем основную ноту
        guard !key.isEmpty else { return .D_high }
        
        let firstChar = key.prefix(1)
        var noteName = String(firstChar)
        
        // Проверяем модификатор (# или b)
        if key.count >= 2 {
            let second = key[key.index(key.startIndex, offsetBy: 1)]
            if second == "#" {
                noteName += "#"
            } else if second == "B" && key.prefix(2) != "BB" {
                // Это может быть Bb или просто B
                if key.hasPrefix("BB") || key.hasPrefix("BM") {
                    noteName = "B"
                }
            }
        }
        
        // Особые случаи: Ador, Edor, Bm и т.д. - миксолидийские/дорийские лады
        if key.contains("DOR") || key.contains("MIN") || key.contains("M") {
            // Для дорийского лада обычно играют на вистле на тон ниже
            // A дорийский → G вистл, E дорийский → D вистл, B минор → A вистл
        }
        
        // Сопоставляем с WhistleKey
        switch noteName {
        case "EB", "E♭":
            return .Eb
        case "D":
            return .D_high
        case "C#", "DB", "D♭":
            return .Csharp
        case "C":
            return .C
        case "B":
            return .B
        case "BB", "B♭", "A#":
            return .Bb
        case "A":
            return .A
        case "AB", "A♭", "G#":
            return .Ab
        case "G":
            return .G
        case "F#", "GB", "G♭":
            return .Fsharp
        case "F":
            return .F
        case "E":
            return .E
        default:
            return .D_high
        }
    }
}

// MARK: - Tune Selector

struct TuneSelectorView: View {
    let tunes: [ABCTune]
    @Binding var selectedIndex: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tunes.enumerated()), id: \.element.id) { index, tune in
                    Button(action: {
                        selectedIndex = index
                        onSelect(index)
                    }) {
                        VStack(spacing: 2) {
                            Text("#\(tune.id)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedIndex == index ? .white : .gray)
                            
                            Text(tune.key)
                                .font(.system(size: 10))
                                .foregroundColor(selectedIndex == index ? .cyan : .gray.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIndex == index
                                      ? Color.purple.opacity(0.3)
                                      : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIndex == index
                                                ? Color.purple.opacity(0.5)
                                                : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
}

struct ControlButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                
                Image(systemName: systemName)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - View Mode Picker

struct ViewModePicker: View {
    @Binding var viewMode: ViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(viewMode == mode ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewMode == mode 
                                  ? LinearGradient(
                                        colors: [
                                            Color(red: 0.5, green: 0.3, blue: 0.7),
                                            Color(red: 0.3, green: 0.5, blue: 0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                  : LinearGradient(
                                        colors: [Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                    )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Transpose Control

struct TransposeControl: View {
    @Binding var transpose: Int
    let originalKey: String
    
    private let semitoneNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Transpose")
                .font(.caption2)
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                // Кнопка минус
                Button(action: {
                    if transpose > -12 {
                        transpose -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange.opacity(0.8))
                }
                
                // Значение
                VStack(spacing: 0) {
                    Text(transpose >= 0 ? "+\(transpose)" : "\(transpose)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(transpose == 0 ? .white : .orange)
                    
                    Text(transposeKeyName)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(width: 50)
                
                // Кнопка плюс
                Button(action: {
                    if transpose < 12 {
                        transpose += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var transposeKeyName: String {
        // Получаем базовую ноту из тональности мелодии
        let baseNoteName = extractNoteName(from: originalKey)
        let baseNoteIndex = semitoneNames.firstIndex(of: baseNoteName) ?? 2
        let newNote = (baseNoteIndex + transpose + 12) % 12
        
        if transpose == 0 {
            return baseNoteName
        }
        return "\(baseNoteName) → \(semitoneNames[newNote])"
    }
    
    /// Извлекает название ноты из тональности (например "Cmaj" → "C", "Ador" → "A")
    private func extractNoteName(from key: String) -> String {
        let key = key.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return "D" }
        
        let firstChar = String(key.prefix(1)).uppercased()
        
        // Проверяем второй символ на # или b
        if key.count >= 2 {
            let secondChar = key[key.index(key.startIndex, offsetBy: 1)]
            if secondChar == "#" {
                return firstChar + "#"
            } else if secondChar == "b" {
                // Преобразуем бемоль в диез для упрощения
                switch firstChar {
                case "D": return "C#"
                case "E": return "D#"
                case "G": return "F#"
                case "A": return "G#"
                case "B": return "A#"
                default: return firstChar
                }
            }
        }
        
        return firstChar
    }
}

// MARK: - Whistle Key Picker

struct WhistleKeyPicker: View {
    @Binding var whistleKey: WhistleKey
    
    var body: some View {
        HStack(spacing: 6) {
            // Кнопка назад (к более высокому)
            Button(action: {
                let keys = WhistleKey.allCases
                if let index = keys.firstIndex(of: whistleKey), index > 0 {
                    whistleKey = keys[index - 1]
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.7))
            }
            
            // Текущий строй
            VStack(spacing: 0) {
                Text(whistleKey.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                Text("whistle")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .frame(minWidth: 50)
            
            // Кнопка вперёд (к более низкому)
            Button(action: {
                let keys = WhistleKey.allCases
                if let index = keys.firstIndex(of: whistleKey), index < keys.count - 1 {
                    whistleKey = keys[index + 1]
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}
