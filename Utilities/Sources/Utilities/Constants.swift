//
//  Constants.swift
//  Moc
//
//  Created by Егор Яковенко on 27.01.2022.
//

import Foundation

public enum Constants {
    public static let unsupportedMessage = "This message is not supported; please update Moc to view it."
    public static let sidebarSizeDefaultsKey = "NSTableViewDefaultSizeMode"
    public static let languagePacksDatabasePath: String = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        print(urls)
        let url = urls.first!
            .appendingPathComponent("Moc")
            .appendingPathComponent("languagePacks.sqlite")
        try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return url.path
    }()

    // MARK: - API credentials loaded from Info.plist

    public static var apiHash: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "API_HASH") as? String else {
            fatalError("API_HASH is missing from Info.plist")
        }
        return value
    }

    public static var apiId: Int {
        guard let valueString = Bundle.main.object(forInfoDictionaryKey: "API_ID") as? String,
              let value = Int(valueString) else {
            fatalError("API_ID is missing or invalid in Info.plist")
        }
        return value
    }
}

public extension Notification.Name {
    static let scrollToMessage = Notification.Name(rawValue: "ScrollToMessage")
    static let updateL10nManager = Notification.Name(rawValue: "UpdateL10nManager")
}
