//
//  Chat+Mock.swift
//  
//
//  Created by Егор Яковенко on 07.07.2022.
//

import TDLibKit

extension Chat {
    static let mock = Chat(
        accentColorId: 0,
        actionBar: nil,
        availableReactions: .chatAvailableReactionsAll(ChatAvailableReactionsAll(maxReactionCount: 1)),
        background: nil,
        backgroundCustomEmojiId: 0,
        blockList: nil,
        businessBotManageBar: nil,
        canBeDeletedForAllUsers: true,
        canBeDeletedOnlyForSelf: true,
        canBeReported: true,
        chatLists: [],
        clientData: "",
        defaultDisableNotification: true,
        draftMessage: nil,
        emojiStatus: nil,
        hasProtectedContent: false,
        hasScheduledMessages: false,
        id: 0,
        isMarkedAsUnread: true,
        isTranslatable: false,
        lastMessage: nil,
        lastReadInboxMessageId: 0,
        lastReadOutboxMessageId: 0,
        messageAutoDeleteTime: 0,
        messageSenderId: nil,
        notificationSettings: .init(
            disableMentionNotifications: true,
            disablePinnedMessageNotifications: true,
            muteFor: 0,
            muteStories: false,
            showPreview: false,
            showStorySender: false,
            soundId: 0,
            storySoundId: 0,
            useDefaultDisableMentionNotifications: false,
            useDefaultDisablePinnedMessageNotifications: false,
            useDefaultMuteFor: false,
            useDefaultMuteStories: false,
            useDefaultShowPreview: false,
            useDefaultShowStorySender: false,
            useDefaultSound: false,
            useDefaultStorySound: false
        ),
        pendingJoinRequests: nil,
        permissions: .init(
            canAddLinkPreviews: false,
            canChangeInfo: false,
            canCreateTopics: false,
            canInviteUsers: false,
            canPinMessages: false,
            canSendAudios: false,
            canSendBasicMessages: false,
            canSendDocuments: false,
            canSendOtherMessages: false,
            canSendPhotos: false,
            canSendPolls: true,
            canSendVideoNotes: false,
            canSendVideos: false,
            canSendVoiceNotes: false
        ),
        photo: nil,
        positions: [],
        profileAccentColorId: 0,
        profileBackgroundCustomEmojiId: 0,
        replyMarkupMessageId: 0,
        themeName: "",
        title: "Ayy",
        type: .chatTypePrivate(ChatTypePrivate(userId: 0)),
        unreadCount: 0,
        unreadMentionCount: 0,
        unreadReactionCount: 0,
        videoChat: .init(
            defaultParticipantId: nil,
            groupCallId: 0,
            hasParticipants: false
        ),
        viewAsTopics: false
    )
}
