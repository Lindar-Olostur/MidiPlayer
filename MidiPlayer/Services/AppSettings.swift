//
//  AppSettings.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 03.12.2025.
//


import SwiftUI

/// Глобальные настройки приложения
class AppSettings: ObservableObject {
    @AppStorage("defaultWhistleKey") var defaultWhistleKey: String = WhistleKey.D_high.rawValue
    @AppStorage("defaultViewMode") var defaultViewMode: String = ViewMode.fingerChart.rawValue
    @AppStorage("defaultTempo") var defaultTempo: Double = 120
    @AppStorage("defaultLooping") var defaultLooping: Bool = true
    
    var whistleKey: WhistleKey {
        get { WhistleKey(rawValue: defaultWhistleKey) ?? .D_high }
        set { defaultWhistleKey = newValue.rawValue }
    }
    
    var viewMode: ViewMode {
        get { ViewMode(rawValue: defaultViewMode) ?? .fingerChart }
        set { defaultViewMode = newValue.rawValue }
    }
}