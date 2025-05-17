//
//  UserFullInfo+Mock.swift
//  
//
//  Created by Егор Яковенко on 28.08.2022.
//

import TDLibKit

extension UserFullInfo {
    static let mock = UserFullInfo(
        bio: FormattedText(entities: [], text: "Bio"),
        birthdate: nil,
        blockList: nil,
        botInfo: nil,
        botVerification: nil,
        businessInfo: nil,
        canBeCalled: false,
        giftCount: 0,
        giftSettings: GiftSettings(
            acceptedGiftTypes: AcceptedGiftTypes(
                limitedGifts: false,
                premiumSubscription: false,
                unlimitedGifts: false,
                upgradedGifts: false
            ),
            showGiftButton: false
        ),
        groupInCommonCount: 2,
        hasPostedToProfileStories: false,
        hasPrivateCalls: false,
        hasPrivateForwards: false,
        hasRestrictedVoiceAndVideoNoteMessages: false,
        hasSponsoredMessagesEnabled: false,
        incomingPaidMessageStarCount: 0,
        needPhoneNumberPrivacyException: true,
        outgoingPaidMessageStarCount: 0,
        personalChatId: 0,
        personalPhoto: nil,
        photo: nil,
        publicPhoto: nil,
        setChatBackground: false,
        supportsVideoCalls: true
    )
}
