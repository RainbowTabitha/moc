//
//  User+Mock.swift
//  
//
//  Created by Егор Яковенко on 28.08.2022.
//

import TDLibKit

extension User {
    static let mock = User(
        accentColorId: 0,
        addedToAttachmentMenu: false,
        backgroundCustomEmojiId: 0,
        emojiStatus: nil,
        firstName: "First name",
        hasActiveStories: false,
        hasUnreadActiveStories: false,
        haveAccess: true,
        id: 0,
        isCloseFriend: false,
        isContact: false,
        isMutualContact: false,
        isPremium: true,
        isSupport: false,
        languageCode: "en_us",
        lastName: "Last name",
        paidMessageStarCount: 0,
        phoneNumber: "+0987654",
        profileAccentColorId: -1,
        profileBackgroundCustomEmojiId: 0,
        profilePhoto: nil,
        restrictionReason: "",
        restrictsNewChats: false,
        status: .userStatusEmpty,
        type: .userTypeRegular,
        usernames: Usernames(
            activeUsernames: ["username"],
            disabledUsernames: [],
            editableUsername: "username"
        ),
        verificationStatus: nil
    )
}
