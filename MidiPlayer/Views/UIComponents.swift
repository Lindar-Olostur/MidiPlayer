//
//  UIComponents.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 29.11.2025.
//

import SwiftUI

// MARK: - Control Button

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

// MARK: - Measure Selector

struct MeasureSelectorView: View {
    @Binding var startMeasure: Int
    @Binding var endMeasure: Int
    let totalMeasures: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Measures")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 20) {
                // Start measure
                VStack(spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if startMeasure > 1 {
                                startMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.purple.opacity(0.8))
                        }
                        
                        Text("\(startMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button(action: {
                            if startMeasure < endMeasure {
                                startMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.purple.opacity(0.8))
                        }
                    }
                }
                
                Text("—")
                    .foregroundColor(.gray)
                
                // End measure
                VStack(spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if endMeasure > startMeasure {
                                endMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                        
                        Text("\(endMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button(action: {
                            if endMeasure < totalMeasures {
                                endMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                    }
                }
            }
            
            // Quick selection buttons
            HStack(spacing: 10) {
                QuickSelectButton(title: "All") {
                    startMeasure = 1
                    endMeasure = totalMeasures
                }
                
                QuickSelectButton(title: "1-4") {
                    startMeasure = 1
                    endMeasure = min(4, totalMeasures)
                }
                
                QuickSelectButton(title: "5-8") {
                    if totalMeasures >= 5 {
                        startMeasure = 5
                        endMeasure = min(8, totalMeasures)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Quick Select Button

struct QuickSelectButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
}

