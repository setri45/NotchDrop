//
//  Language.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/31.
//

import Cocoa

private var languageSwitchedBefore: Bool = false

enum Language: String, CaseIterable, Identifiable, Codable {
    case system = "Follow System"
    case english = "English"
    case simplifiedChinese = "Simplified Chinese"
    case traditionalChinese = "Traditional Chinese"

    var id: String { rawValue }

    var localized: String {
        NSLocalizedString(rawValue, comment: "")
    }

    func apply() {
        defer { languageSwitchedBefore = true }

        let languageCode: String?
        let local = Calendar.autoupdatingCurrent.locale?.identifier
        let region = local?.split(separator: "@").last?.split(separator: "_").last

        switch self {
        case .system:
            if region == "rg=hkzzzz" || region == "rg=twzzzz" || region == "rg=mozzzz"
                || region == "TW" || region == "HK" || region == "MO"
            {
                languageCode = "zh-Hant"
            } else if region == "CN" {
                languageCode = "zh-Hans"
            } else {
                languageCode = "en"
            }
        case .english:
            languageCode = "en"
        case .simplifiedChinese:
            languageCode = "zh-Hans"
        case .traditionalChinese:
            languageCode = "zh-Hant"
        }

        Bundle.setLanguage(languageCode)

        if languageSwitchedBefore {
            NSAlert.popRestart(
                NSLocalizedString("The language has been changed. The app will restart for the changes to take effect.", comment: ""),
                completion: restartApp
            )
        }
    }
}

private func restartApp() {
    guard let appPath = Bundle.main.executablePath else { return }
    NSApp.terminate(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: appPath)
        do { try process.run() } catch {}
        exit(0)
    }
}

private extension Bundle {
    private static var onLanguageDispatchOnce: () -> Void = {
        object_setClass(Bundle.main, PrivateBundle.self)
    }

    static func setLanguage(_ language: String?) {
        onLanguageDispatchOnce()

        if let language {
            UserDefaults.standard.set([language], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}

private class PrivateBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
              let languageCode = languages.first,
              let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
