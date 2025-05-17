//
//  TdFoldersPrefService.swift
//
//
//  Created by Егор Яковенко on 28.05.2022.
//

import Storage
import TDLibKit
import GRDB
import Combine

public class TdFoldersPrefService: FoldersPrefService {
    private var tdApi: TdApi = .shared
    
    public var updateSubject: PassthroughSubject<Update, Never> {
        let subject = PassthroughSubject<Update, Never>()
        self.tdApi.client.run { [weak self] data in
            guard let self = self else { return }
            if let update = try? self.tdApi.decoder.decode(Update.self, from: data) {
                subject.send(update)
            }
        }
        return subject
    }

    public init() { }

    public func getFilters() async throws -> [ChatFolderInfo] {
        try! StorageService.cache.getRecords(as: Storage.ChatFolder.self, ordered: [Column("order").asc])
            .map(ChatFolderInfo.init(from:))
    }

    public func getFilter(by id: Int) async throws -> TDLibKit.ChatFolder {
        try await tdApi.getChatFolder(chatFolderId: id)
    }

    public func reorderFilters(_ folders: [Int]) async throws {
        try await tdApi.reorderChatFolders(chatFolderIds: folders, mainChatListPosition: 0)
    }

    public func createFilter(_ filter: TDLibKit.ChatFolder) async throws {
        _ = try await tdApi.createChatFolder(folder: filter)
    }

    public func deleteFilter(by id: Int) async throws {
        try await tdApi.deleteChatFolder(chatFolderId: id, leaveChatIds: [Int64(id)])
    }

    public func getRecommended() async throws -> [RecommendedChatFolder] {
        try await tdApi.getRecommendedChatFolders().chatFolders
    }

    public func leaveChat(chatId: Int64) async throws {
        try await tdApi.leaveChat(chatId: chatId)
    }
}
