//
//  CachingChatFilter.swift
//
//
//  Created by Егор Яковенко on 31.05.2022.
//

import Storage
import TDLibKit

extension TDLibKit.ChatFolderInfo {
    init(from cached: Storage.ChatFolder) {
        self.init(
            colorId: -1,
            hasMyInviteLinks: false,
            icon: .init(name: cached.iconName),
            id: cached.id,
            isShareable: false,
            name: .init(
                animateCustomEmoji: false,
                text: .init(entities: [], text: cached.title)
            )
        )
    }
}
