//
//  TdChatInspectorService.swift
//  
//
//  Created by Егор Яковенко on 05.09.2022.
//

import TDLibKit
import Combine
import Foundation

public class TdChatInspectorService: ChatInspectorService {
    private var tdApi = TdApi.shared
    
    public var updateSubject: PassthroughSubject<Update, Never> {
        let subject = PassthroughSubject<Update, Never>()
        self.tdApi.client.run { data in
            if let update = try? JSONDecoder().decode(Update.self, from: data) {
                subject.send(update)
            }
        }
        return subject
    }
    
    public init() { }
    
    public func getChat(with id: Int64) async throws -> Chat {
        try await tdApi.getChat(chatId: id)
    }
}
