//
//  MockChatService.swift
//
//
//  Created by Егор Яковенко on 18.01.2022.
//

import Resolver
import TDLibKit
import Foundation
import Combine

// swiftlint:disable:next all
public class MockChatService: ChatService {
    public func updateDraft(_ newDraft: TDLibKit.DraftMessage?, threadId: Int64?) async throws { }
    
    public func getUser(by id: Int64) async throws -> TDLibKit.User {
        // TODO: Move this to a static `mock` variable
        User(
            accentColorId: 0,
            addedToAttachmentMenu: false,
            backgroundCustomEmojiId: 0,
            emojiStatus: nil,
            firstName: "First",
            hasActiveStories: false,
            hasUnreadActiveStories: false,
            haveAccess: true,
            id: id,
            isCloseFriend: false,
            isContact: true,
            isMutualContact: true,
            isPremium: true,
            isSupport: true,
            languageCode: "en_us",
            lastName: "Last",
            paidMessageStarCount: 0,
            phoneNumber: "phone",
            profileAccentColorId: 0,
            profileBackgroundCustomEmojiId: 0,
            profilePhoto: nil,
            restrictionReason: "",
            restrictsNewChats: false,
            status: .userStatusEmpty,
            type: .userTypeRegular,
            usernames: .init(activeUsernames: ["username"], disabledUsernames: [], editableUsername: "username"),
            verificationStatus: nil
        )
    }
    
    public func getChat(by id: Int64) async throws -> TDLibKit.Chat {
        Chat.mock
    }
    
    public func sendTextMessage(_ message: TDLibKit.FormattedText, clearDraft: Bool, disablePreview: Bool) async throws -> TDLibKit.Message {
        Message.mock
    }
    
    public func sendMedia(_ url: URL, caption: String) async throws -> TDLibKit.Message {
        Message.mock
    }
    
    public func sendAlbum(_ urls: [URL], caption: String) async throws -> [TDLibKit.Message]? {
        [Message.mock, Message.mock]
    }
    
    public func setProtected(_ isProtected: Bool) async throws { }
    
    public func setBlocked(_ isBlocked: Bool) async throws { }
    
    public func setChatTitle(_ title: String) async throws { }
    
    public func setAction(_ action: TDLibKit.ChatAction) async throws { }
    
    public func getMessage(by id: Int64) async throws -> TDLibKit.Message {
        Message.mock
    }
    
    public func getMessageHistory() async throws -> [TDLibKit.Message] {
        [Message.mock, Message.mock, Message.mock]
    }
    
    public var chatId: Int64? = 1234567890
    
    public var updateSubject = PassthroughSubject<TDLibKit.Update, Never>()
    
    public init() { }
}
