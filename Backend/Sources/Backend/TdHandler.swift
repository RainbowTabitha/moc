import Storage
import Foundation
import Logs
import TDLibKit
import Utilities
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension TdApi {
    
    // Static shared queue for TdLib tasks
    static let queue = DispatchQueue(label: "TDLib", qos: .userInteractive)
    
    // Logger instance
    private static let logger = Logs.Logger(category: "TDLib", label: "Updates")
    
    // TDLib client manager singleton
    private static let manager = TDLibClientManager()

    // Wrapper to adapt TDLibClient to TdClient protocol
    private class MyTDLibClientWrapper: TdClient {
        private let client: TDLibClient

        init(client: TDLibClient) {
            self.client = client
        }

        public func run(updateHandler: @escaping (Data) -> Void) {
            client.run { data, _ in
                Task {
                    do {
                        updateHandler(data)
                    } catch {
                        logger.error(error)
                    }
                }
            }
        }

        public func send(query: TdQuery, completion: ((Data) -> Void)?) throws {
            try client.send(query: query, completion: completion)
        }

        public func execute(query: TdQuery) throws -> [String:Any]? {
            try client.execute(query: query)
        }

        public func close() {
            client.close()
        }
    }

    private static let rawClient: TDLibClient = manager.createClient { (data: Data, client: TDLibClient) in
        logger.debug("Received raw update: \(data)")
    }

    private static let client: TdClient = MyTDLibClientWrapper(client: rawClient)
    
    // Singleton instance of TdApi wrapping the client
    static var shared: TdApi = TdApi(client: client)
    
    // Start the TDLib update handler
    static func startTdLibUpdateHandler() {
        logger.debug("Starting handler")
        
        Task {
            #if DEBUG
            try await shared.setLogVerbosityLevel(newVerbosityLevel: 2)
            #else
            try await shared.setLogVerbosityLevel(newVerbosityLevel: 0)
            #endif
            
            try await shared.setOption(
                name: "language_pack_database_path",
                value: .optionValueString(OptionValueString(value: Constants.languagePacksDatabasePath))
            )
            
            try await shared.setOption(
                name: "localization_target",
                value: .optionValueString(OptionValueString(value: "ios"))
            )
            
            try await fetchLocalization()
        }
        
        client.run { data in
            let cache = StorageService.cache
            
            do {
                let update = try JSONDecoder().decode(Update.self, from: data)
                
                switch update {
                case let .updateAuthorizationState(update):
                    switch update.authorizationState {
                    case .authorizationStateWaitTdlibParameters:
                        Task {
                            var url = try FileManager.default.url(
                                for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)
                            url.append(path: "td")
                            try await shared.setTdlibParameters(
                                apiHash: Constants.apiHash,
                                apiId: Constants.apiId,
                                applicationVersion: SystemUtils.info(key: "CFBundleShortVersionString"),
                                databaseDirectory: url.path(),
                                databaseEncryptionKey: nil,
                                deviceModel: await SystemUtils.getDeviceModel(),
                                filesDirectory: url.path(),
                                systemLanguageCode: "en-US",
                                systemVersion: SystemUtils.osVersionString,
                                useChatInfoDatabase: true,
                                useFileDatabase: true,
                                useMessageDatabase: true,
                                useSecretChats: false,
                                useTestDc: false
                            )
                        }
                    case .authorizationStateReady:
                        Task {
                            try await shared.loadChats(chatList: .chatListMain, limit: 15)
                            try await shared.loadChats(chatList: .chatListArchive, limit: 15)
                        }
                    case .authorizationStateClosed:
                        let newRawClient = manager.createClient { data, client in
                            logger.debug("Received raw update: \(data)")
                        }
                        shared = TdApi(client: MyTDLibClientWrapper(client: newRawClient))
                        startTdLibUpdateHandler()
                    default:
                        break
                    }
                case let .updateChatFolders(update):
                    try cache.deleteAll(records: Storage.ChatFolder.self)
                    for (index, filter) in update.updateChatFolders.enumerated() {
                        try cache.save(record: Storage.ChatFolder(
                            title: filter.title,
                            id: filter.id,
                            iconName: filter.iconName,
                            order: index))
                    }
                case let .unreadChatCount(update):
                    var shouldBeAdded = true
                    let chatList = Storage.ChatList.from(tdChatList: update.chatList)
                    let records = try cache.getRecords(as: UnreadCounter.self)
                    
                    for record in records where chatList == record.chatList {
                        try cache.modify(record: UnreadCounter.self, at: chatList) { record in
                            record.chats = update.unreadCount
                        }
                        shouldBeAdded = false
                    }
                    
                    if shouldBeAdded {
                        try cache.save(record: UnreadCounter(
                            chats: update.unreadCount,
                            messages: 0,
                            chatList: chatList
                        ))
                    }
                case let .unreadMessageCount(update):
                    var shouldBeAdded = true
                    let chatList = Storage.ChatList.from(tdChatList: update.chatList)
                    let records = try cache.getRecords(as: UnreadCounter.self)
                    
                    for record in records where chatList == record.chatList {
                        try cache.modify(record: UnreadCounter.self, at: chatList) { record in
                            record.messages = update.unreadCount
                        }
                        shouldBeAdded = false
                    }
                    
                    if shouldBeAdded {
                        try cache.save(record: UnreadCounter(
                            chats: 0,
                            messages: update.unreadCount,
                            chatList: chatList
                        ))
                    }
                case let .fileGenerationStart(info):
                    switch info.conversion {
                    case "copy":
                        Task {
                            do {
                                logger.debug("Starting copy conversion with id \(info.generationId.rawValue)")
                                if FileManager.default.fileExists(atPath: info.destinationPath) {
                                    try FileManager.default.removeItem(atPath: info.destinationPath)
                                }
                                try FileManager.default.copyItem(
                                    at: URL(filePath: info.originalPath),
                                    to: URL(filePath: info.destinationPath))
                                logger.debug("Copy conversion done for id \(info.generationId.rawValue)")
                                try await shared.finishFileGeneration(error: nil, generationId: info.generationId)
                            } catch {
                                try await shared.finishFileGeneration(error: Error(code: 400, message: error.localizedDescription), generationId: info.generationId)
                            }
                        }
                    case "video_thumbnail":
                        Task {
                            do {
                                let thumbnail = URL(fileURLWithPath: info.originalPath).platformThumbnail
                                #if os(macOS)
                                if let imgRep = thumbnail.representations.first as? NSBitmapImageRep,
                                   let data = imgRep.representation(using: .png, properties: [:]) {
                                    try data.write(to: URL(fileURLWithPath: info.destinationPath), options: .atomic)
                                }
                                #elseif os(iOS)
                                if let data = thumbnail.pngData() {
                                    try data.write(to: URL(fileURLWithPath: info.destinationPath), options: .atomic)
                                }
                                #endif
                                try await shared.finishFileGeneration(error: nil, generationId: info.generationId)
                                logger.debug("File generation done for ID \(info.generationId)")
                            } catch {
                                logger.debug("File generation failed for ID \(info.generationId)")
                                try await shared.finishFileGeneration(error: Error(code: 400, message: error.localizedDescription), generationId: info.generationId)
                            }
                        }
                    default:
                        break
                    }
                case let .connectionState(update):
                    if case .ready = update.state {
                        Task {
                            try await fetchLocalization()
                        }
                    }
                default:
                    break
                }
            } catch {
                logger.error(error)
            }
        }
    }
    
    // Fetch localization packs asynchronously
    private static func fetchLocalization() async throws {
        let tdLanguagePacks = try await shared.getLocalizationTargetInfo(onlyLocal: false).languagePacks
        for pack in tdLanguagePacks {
            _ = try await shared.getLanguagePackStrings(keys: nil, languagePackId: pack.id)
        }
    }
}
