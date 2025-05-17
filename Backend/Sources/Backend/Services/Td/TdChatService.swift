//
//  TdChatService.swift
//
//
//  Created by Егор Яковенко on 18.01.2022.
//

import Combine
import Foundation
import AVKit
import SwiftUI
import Utilities
import TDLibKit
import Logs
import UniformTypeIdentifiers

// swiftlint:disable:next function_body_length
public class TdChatService: ChatService {
    private var logger = Logs.Logger(category: "Services", label: "TdChatDataSource")
    private var tdApi = TdApi.shared
    
    public var updateSubject: PassthroughSubject<Update, Never> {
        _updateSubject
    }
    private let _updateSubject = PassthroughSubject<Update, Never>()
    
    public func updateDraft(_ newDraft: TDLibKit.DraftMessage?, threadId: Int64? = nil) async throws {
        if let chatId {
            try await tdApi.setChatDraftMessage(
                chatId: chatId,
                draftMessage: newDraft,
                messageThreadId: nil)
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func getUser(by id: Int64) async throws -> TDLibKit.User {
        return try await tdApi.getUser(userId: id)
    }
    
    public func getChat(by id: Int64) async throws -> TDLibKit.Chat {
        return try await tdApi.getChat(chatId: id)
    }
    
    public func sendTextMessage(
        _ message: FormattedText,
        clearDraft: Bool,
        disablePreview: Bool
    ) async throws -> Message {
        if let chatId {
            let linkPreviewOptions = LinkPreviewOptions(
                forceLargeMedia: false,
                forceSmallMedia: false,
                isDisabled: disablePreview,
                showAboveText: false,
                url: ""
            )
            return try await tdApi.sendMessage(
                chatId: chatId,
                inputMessageContent: .inputMessageText(InputMessageText(
                    clearDraft: clearDraft,
                    linkPreviewOptions: linkPreviewOptions,
                    text: message
                )),
                messageThreadId: 0,
                options: nil,
                replyMarkup: nil,
                replyTo: nil
            )
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func sendMedia(_ url: URL, caption: String) async throws -> Message {
        if let chatId {
            return try await tdApi.sendMessage(
                chatId: chatId,
                inputMessageContent: try await makeInputMessageContent(
                    for: url,
                    caption: FormattedText(entities: [], text: caption)),
                messageThreadId: nil,
                options: nil,
                replyMarkup: nil,
                replyTo: nil
            )
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func sendAlbum(_ urls: [URL], caption: String) async throws -> [Message]? {
        var messageContents: [InputMessageContent] = []
        try await withThrowingTaskGroup(of: InputMessageContent?.self) { group in
            for url in urls {
                group.addTask {
                    try? await self.makeInputMessageContent(for: url, caption: FormattedText(entities: [], text: caption))
                }
            }
            for try await result in group {
                if let content = result {
                    messageContents.append(content)
                }
            }
        }
        if let chatId {
            return try await tdApi.sendMessageAlbum(
                chatId: chatId,
                inputMessageContents: messageContents,
                messageThreadId: 0,
                options: nil,
                replyTo: nil
            ).messages
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func setProtected(_ isProtected: Bool) async throws {
        if let chatId {
            try await tdApi.toggleChatHasProtectedContent(
                chatId: chatId,
                hasProtectedContent: isProtected)
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func setBlocked(_ isBlocked: Bool) async throws {
        if let chatId {
            let chat = try await getChat(by: chatId)
            switch chat.type {
                case .chatTypePrivate:
                    // Implement block/unblock logic for private chat if available
                    throw ServiceError.cantBeBlocked // Placeholder
                case .chatTypeSupergroup:
                    // Implement block/unblock logic for supergroup chat if available
                    throw ServiceError.cantBeBlocked // Placeholder
                default:
                    throw ServiceError.cantBeBlocked
            }
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func setChatTitle(_ title: String) async throws {
        if let chatId {
            try await tdApi.setChatTitle(chatId: chatId, title: title)
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func setAction(_ action: TDLibKit.ChatAction) async throws {
        if let chatId {
            try await tdApi.sendChatAction(
                action: action,
                businessConnectionId: nil,
                chatId: chatId,
                messageThreadId: nil)
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func getMessage(by id: Int64) async throws -> TDLibKit.Message {
        if let chatId {
            return try await tdApi.getMessage(chatId: chatId, messageId: id)
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public func getMessageHistory() async throws -> [Message] {
        if let chatId {
            return try await tdApi.getChatHistory(
                chatId: chatId,
                fromMessageId: 0,
                limit: 50,
                offset: 0,
                onlyLocal: false
            ).messages ?? []
        } else {
            throw ServiceError.noChatIdSet
        }
    }
    
    public var chatId: Int64?
    
    private func makeInputMessageContent(for url: URL, caption: FormattedText) async throws -> InputMessageContent {
        var path = url.absoluteString
        path = String(path.suffix(from: .init(utf16Offset: 7, in: path))).removingPercentEncoding ?? ""
        let uti = UTType(url)
        logger.debug("UTType: \(String(describing: uti))")
        let inputLocal = InputFile.inputFileLocal(InputFileLocal(path: path))
        if uti?.conforms(to: .image) == true {
            return .inputMessagePhoto(InputMessagePhoto(
                addedStickerFileIds: [],
                caption: caption,
                hasSpoiler: false,
                height: 0,
                photo: inputLocal,
                selfDestructType: nil,
                showCaptionAboveMedia: false,
                thumbnail: nil,
                width: 0
            ))
        } else if uti?.conforms(to: .movie) == true {
            return .inputMessageVideo(InputMessageVideo(
                addedStickerFileIds: [],
                caption: caption,
                cover: nil,
                duration: 0,
                hasSpoiler: false,
                height: 0,
                selfDestructType: nil,
                showCaptionAboveMedia: false,
                startTimestamp: 0,
                supportsStreaming: true,
                thumbnail: nil,
                video: inputLocal,
                width: 0
            ))
        } else {
            return .inputMessageDocument(InputMessageDocument(
                caption: caption,
                disableContentTypeDetection: false,
                document: inputLocal,
                thumbnail: nil
            ))
        }
    }
    
    public init() {
        // Setup update handler for TDLib updates
        tdApi.client.run { [weak self] data in
            guard let self = self else { return }
            if let update = try? JSONDecoder().decode(Update.self, from: data) {
                self.updateSubject.send(update)
            }
        }
    }
}
