//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public class SpeechToTextRef {
    static let shared = SpeechToTextRef()
    
    private let store = KeyValueStore(collection: "speechToText")

    // Metodo per salvare l'impostazione
    func setSetting(_ value: Int, transaction: DBWriteTransaction) {
        store.setInt(value, key: "enabled", transaction: transaction)
    }
    
    // Metodo per recuperare l'impostazione
    func getSetting(transaction: DBReadTransaction) -> Int {
        return store.getInt("enabled", transaction: transaction) ?? 0
    }
}
