//
//  OrientationService.swift
//  MidiPlayer
//
//  Created by Lindar Olostur on 30.11.2025.
//
import SwiftUI

@Observable
class OrientationService {
    var currentOrientation: UIDeviceOrientation = {
        // Определяем начальную ориентацию более надежно
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation != .unknown {
            return deviceOrientation
        }

        // Если UIDevice возвращает unknown, используем размер экрана
        #if os(iOS)
        let screenSize = UIScreen.main.bounds.size
        return screenSize.width > screenSize.height ? .landscapeLeft : .portrait
        #else
        return .portrait
        #endif
    }()
    var isRotationEnabled = true

    /// Упрощенное определение режима (портрет/ландшафт) для интерфейса
    var isPortrait: Bool {
        switch currentOrientation {
        case .portrait, .portraitUpsideDown:
            return true
        case .landscapeLeft, .landscapeRight:
            return false
        default:
            // Для unknown и других случаев используем размер экрана
            #if os(iOS)
            let screenSize = UIScreen.main.bounds.size
            return screenSize.width <= screenSize.height
            #else
            return true
            #endif
        }
    }

    func setupOrientationObserver() {
        // Включаем отслеживание ориентации устройства
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newOrientation = UIDevice.current.orientation
            // Игнорируем unknown ориентации
            if newOrientation != .unknown {
                self.currentOrientation = newOrientation
            }
        }
    }
    
    func removeOrientationObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        // Отключаем отслеживание ориентации устройства
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}
