//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

final class SpeechToTextSettings {
    static let shared = SpeechToTextSettings()
    
    private init() {}
    
    var selectedOption: SpeechToTextOption = .native {
        didSet {
            // Qui puoi aggiungere logica da eseguire quando cambia l'opzione
            NotificationCenter.default.post(name: .speechToTextOptionDidChange, object: selectedOption)
        }
    }
    
    private func logSelectedOption() {
        print("""
            Speech-to-text settings updated:
            Option: \(selectedOption.rawValue)
            Description: \(selectedOption.description)
            Download Size: \(selectedOption.downloadSize)
            """)
    }
}

// Estensione per la notifica
extension Notification.Name {
    static let speechToTextOptionDidChange = Notification.Name("speechToTextOptionDidChange")
}
