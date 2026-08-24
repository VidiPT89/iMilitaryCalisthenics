import Foundation
import Observation

enum Lang: String, CaseIterable {
    case pt, en
}

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    private let key = "app.language"
    var current: Lang {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: key) }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key), let lang = Lang(rawValue: raw) {
            current = lang
        } else {
            current = .pt
        }
    }

    func toggle() {
        current = current == .pt ? .en : .pt
    }

    func t(_ key: String) -> String {
        Translations.table[key]?[current] ?? key
    }
}

func t(_ key: String) -> String {
    LocalizationManager.shared.t(key)
}
