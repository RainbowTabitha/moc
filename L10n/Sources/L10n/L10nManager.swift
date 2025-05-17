//
//  L10nManager.swift
//  
//
//  Created by Егор Яковенко on 19.10.2022.
//

import Foundation
import L10n_swift
import TDLibKit
import Backend
import Combine
import Logs
import Utilities
#if os(macOS)
import AppKit
#endif

public class L10nManager {
    public static let shared = L10nManager()
    private let tdApi = TdApi.shared
    private var subscribers: [AnyCancellable] = []
    public private(set) var languagePackID = ""
    private let logger = Logger(category: "Localization", label: "Manager")
    private let localStrings: [String: String] = {
        if let url = Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: "en.lproj"),
           let stringsDict = NSDictionary(contentsOf: url) as? [String: String] {
           return stringsDict
        }
        return [:]
    }()
    
    private var cloudCache: [String: [String: String]] = [:]
    
    init() {
        logger.debug("Initialized L10nManager")
        Task {
            guard let option = try? await tdApi.getOption(
                name: "language_pack_id") else { return }
            if case .optionValueString(let string) = option {
                guard let pack = try? await tdApi.getLanguagePackInfo(
                    languagePackId: string.value) else { return }
                try? await self.setLanguage(from: pack)
            }
        }
    }
        
    public func setLanguage(from languagePack: LanguagePackInfo) async throws {
        self.languagePackID = languagePack.id
        
        if languagePack.id.count == 2 {
            L10n.shared.language = languagePack.id
        } else {
            if languagePack.baseLanguagePackId.count == 2 {
                L10n.shared.language = languagePack.baseLanguagePackId
            } else {
                L10n.shared.language = "en"
            }
        }
        
        try await TdApi.shared.setOption(
            name: "language_pack_id",
            value: .optionValueString(OptionValueString(value: languagePack.id)))
    }
    
    public func setLanguageSync(from languagePack: LanguagePackInfo) {
        Task {
            try? await setLanguage(from: languagePack)
        }
    }
    
    public func getString(
        by key: String,
        source: LocalizationSource = .automatic,
        arg: Any? = nil
    ) async -> String {
        switch source {
            case .strings:
                return getLocalizableString(by: key)
            case .telegram:
                return await getTelegramString(by: key, arg: arg)
            case .automatic:
                let localizable = getLocalizableString(by: key)
                if localizable == key { // If not found
                    return await getTelegramString(by: key, arg: arg)
                } else {
                    return localizable
                }
        }
    }
    
    func getLocalizableString(by key: String) -> String {
        if localStrings.contains(where: { $0.key == key }) {
            return key.l10n()
        } else {
            return key
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func getTelegramString(
        by key: String,
        from languagePackID: String? = nil,
        arg: Any? = nil
    ) async -> String {
        do {
            let langString = try tdApi.getLanguagePackString(
                key: key,
                languagePackDatabasePath: Constants.languagePacksDatabasePath,
                languagePackId: languagePackID ?? self.languagePackID,
                localizationTarget: "ios"
            )
            
            switch langString {
                case .languagePackStringValueOrdinary(let ordinary):
                    if let arg {
                        return String(format: ordinary.value, arg as! CVarArg)
                    } else {
                        return ordinary.value
                    }
                case .languagePackStringValuePluralized(let pluralized):
                    if let arg {
                        guard let intArg = arg as? Int else { return pluralized.otherValue }
                        let lastDigit = intArg % 10
                        
                        print(pluralized)
                        
                        func format(for value: String) -> String {
                            if value == "" {
                                return String(format: pluralized.otherValue, arg as! CVarArg)
                            } else {
                                return String(format: value, arg as! CVarArg)
                            }
                        }
                        
                        switch lastDigit {
                            case 0: return format(for: pluralized.zeroValue)
                            case 1: return format(for: pluralized.oneValue)
                            case 2: return format(for: pluralized.twoValue)
                            case 2...4: return format(for: pluralized.fewValue)
                            case 4...9: return format(for: pluralized.manyValue)
                            default: return format(for: pluralized.otherValue)
                        }
                    } else {
                        return pluralized.otherValue
                    }
                case .languagePackStringValueDeleted:
                    if languagePackID == "en" { // If a string doesn't exist even in English language pack
                        logger.debug("String not found in English pack, returning key")
                        return key
                    } else {
                        logger.debug("String not found in pack \(String(describing: languagePackID))")
                        return await getTelegramString(by: key, from: "en", arg: arg)
                    }
            }
        } catch {
            logger.error(error)
            return key
        }
    }
}
