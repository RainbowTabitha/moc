//
//  CachingChatList.swift
//  
//
//  Created by Егор Яковенко on 05.06.2022.
//

import Storage
import TDLibKit

public extension Storage.ChatList {
    static func from(tdChatList: TDLibKit.ChatList) -> Self {
        switch tdChatList {
            case .chatListMain:
                return Storage.ChatList.main
            case .chatListArchive:
                return Storage.ChatList.archive
            case let .chatListFolder(info):
                return Storage.ChatList.folder(info.chatFolderId)
        }
    }
}