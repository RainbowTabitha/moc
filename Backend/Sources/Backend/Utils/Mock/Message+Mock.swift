//
//  Message+Mock.swift
//  
//
//  Created by Егор Яковенко on 27.08.2022.
//

import TDLibKit

extension Message {
    static let mock = Message(
        authorSignature: "",
        autoDeleteIn: 0,
        canBeSaved: false,
        chatId: 0,
        containsUnreadMention: false,
        content: .messageText(.init(
            linkPreview: nil,
            linkPreviewOptions: nil,
            text: .init(entities: [], text: "")
        )),
        date: 0,
        editDate: 0,
        effectId: 0,
        factCheck: nil,
        forwardInfo: nil,
        hasSensitiveContent: false,
        hasTimestampedMedia: false,
        id: 0,
        importInfo: nil,
        interactionInfo: nil,
        isChannelPost: false,
        isFromOffline: false,
        isOutgoing: false,
        isPinned: false,
        isTopicMessage: false,
        mediaAlbumId: 0,
        messageThreadId: 0,
        paidMessageStarCount: 0,
        replyMarkup: nil,
        replyTo: nil,
        restrictionReason: "",
        savedMessagesTopicId: 0,
        schedulingState: nil,
        selfDestructIn: 0,
        selfDestructType: nil,
        senderBoostCount: 0,
        senderBusinessBotUserId: 0,
        senderId: .messageSenderChat(.init(chatId: 0)),
        sendingState: nil,
        unreadReactions: [],
        viaBotUserId: 0
    )
}
