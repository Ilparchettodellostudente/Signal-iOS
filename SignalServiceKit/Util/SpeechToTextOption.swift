//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public enum SpeechToTextOption: String, CaseIterable {
    case native = "Native"
    case base = "Base"
    case medium = "Medium"
    case high = "High"
    case custom = "Custom"
    
    public var title: String {
        return self.rawValue
    }
    
    public var description: String {
        switch self {
        case .native:
            return "Integrated into the operating system"
        case .base:
            return "Light and fast"
        case .medium:
            return "Balanced between accuracy and performance"
        case .high:
            return "Greater accuracy"
        case .custom:
            return "Manual choice"
        }
    }
    
    public var downloadSize: String {
        switch self {
        case .native:
            return "No download required"
        case .base:
            return "~50MB"
        case .medium:
            return "~150MB"
        case .high:
            return "~300MB"
        case .custom:
            return "Size varies"
        }
    }
    
    public var downloadDescription: String {
        switch self {
        case .native:
            return "No download required"
        default:
            let baseText = "The selected model (\(self.downloadSize)) will be downloaded in the background"
            return self == .custom ? "\(baseText)\nYou can change the model settings later" : baseText
        }
    }
}
