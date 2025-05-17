//
//  TdMainService.swift
//  
//
//  Created by Егор Яковенко on 03.06.2022.
//

import TDLibKit
import Storage
import GRDB
import Combine

public class TdMainService: MainService {
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
    
    private var tdApi = TdApi.shared
    private var cache = StorageService.cache
    
    public init() { }
    
    public func getFilters() throws -> [ChatFilter] {
        return try cache.getRecords(as: ChatFolder.self, ordered: [Column("order").asc])
            .map { record in
                ChatFilter(
                    title: record.title,
                    id: record.id,
                    iconName: record.iconName,
                    order: record.order
                )
            }
    }
    
    public func getUnreadCounters() throws -> [UnreadCounter] {
        return try cache.getRecords(as: UnreadCounter.self)
    }
    
    public func getChat(by id: Int64) async throws -> TDLibKit.Chat {
        try await tdApi.getChat(chatId: id)
    }
}
