//
//  MainViewModel.swift
//  Moc
//
//  Created by Егор Яковенко on 01.01.2022.
//

import Resolver
import SwiftUI
import Utilities
import Combine
import Logs
import OrderedCollections
import Backend
import Storage
import Network
import Defaults
import MenuBar

class MainViewModel: ObservableObject {
    @Injected var service: any MainService
    
    @Published var connectionState: ConnectionState = .waitingForNetwork
    
    @Published var isChatListVisible = true
        
    // just a helper function to filter out a set of chat positions
    private func getPosition(from positions: [ChatPosition], chatList: TDLibKit.ChatList) -> ChatPosition? {
        return positions.first { position in
            position.list == chatList
        }
    }
    
    private func chats(from chatList: TDLibKit.ChatList) -> [Chat] {
        let chats = self.allChats.filter { chat in
            guard let positions = self.chatPositions[chat.id] else { return false }
            return self.getPosition(from: positions, chatList: chatList) != nil
        }
        
        return chats.sorted { previous, next in
            guard let previousPosition = self.getPosition(
                from: self.chatPositions[previous.id] ?? [],
                chatList: chatList)?.order else { return false }
            guard let nextPosition = self.getPosition(
                from: self.chatPositions[next.id] ?? [],
                chatList: chatList)?.order else { return false }
            
            return previousPosition > nextPosition
        }
    }
    
    var chatList: [Chat] {
        switch openChatList {
            case .main:
                return chats(from: .main)
            case .archive:
                return chats(from: .archive)
            case .folder(let id):
                return chats(from: .filter(.init(chatFilterId: id)))
            case .none:
                return []
        }
    }
    
    @Published var unreadCounters: [Storage.UnreadCounter] = []
    @Published var updateChatFolders: [TDLibKit.ChatFilterInfo] = []
    
    var mainUnreadCounter: Int {
        unreadCounters
            .first { $0.chatList == .main }?.chats ?? 0
    }
    
    var folders: [ChatFolder] {
        return updateChatFolders.map { filter in
            return ChatFolder(
                title: filter.title,
                id: filter.id,
                iconName: filter.iconName,
                unreadCounter: unreadCounters
                    .first { $0.chatList == .folder(filter.id) }?
                    .chats ?? 0)
        }
    }
    
    @Published var allChats = Set<Chat>()
    @Published var chatPositions: [Int64: [ChatPosition]] = [:]
    
    @Published var openChatList: Storage.ChatList? = .main {
        didSet {
            if let openChatList {
                logger.trace("openChatList: \(openChatList)")
                if openChatList != .archive {
                    openChatListBuffer = openChatList
                }
                Task {
                    switch openChatList {
                        case .main:
                            try await TdApi.shared.loadChats(
                                chatList: .main,
                                limit: 30)
                        case .archive:
                            try await TdApi.shared.loadChats(
                                chatList: .archive,
                                limit: 30)
                        case .folder(let id):
                            try await TdApi.shared.loadChats(
                                chatList: .filter(.init(chatFilterId: id)),
                                limit: 30)
                    }
                }
            }
        }
    }
    
    private var openChatListBuffer: Storage.ChatList = .main {
        didSet {
            logger.trace("openChatListBuffer: \(openChatListBuffer)")
        }
    }
    
    @Published var isArchiveOpen = false {
        didSet {
            if isArchiveOpen {
                openChatList = .archive
            } else {
                openChatList = openChatListBuffer
            }
        }
    }

    @Published var showingLoginScreen = false
//    @Published var isSessionTerminationAlertShown = false
    
    @Published var sidebarSize: SidebarSize = .medium
    
    private var subscribers: [AnyCancellable] = []
    private var logger = Logs.Logger(category: "UI", label: "MainViewModel")
    private var nwPathMonitorQueue = DispatchQueue(label: "NWPathMonitorQueue", qos: .utility)

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    init() {
        service.updateSubject
            .receive(on: RunLoop.main)
            .sink { [self] update in
                switch update {
                    case let .chatPosition(info):
                        updateChatPosition(info)
                    case let .authorizationState(info):
                        switch info.authorizationState {
                            case .closed:
//                                isSessionTerminationAlertShown = true
                                allChats.removeAll()
                                updateChatFolders.removeAll()
                            case .ready, .waitEncryptionKey, .waitTdlibParameters: break // do nothing
                            default:
                                showingLoginScreen = true
                        }
                    case let .newChat(info):
                        updateNewChat(info)
                    case let .updateChatFolders(info):
                        updateupdateChatFolders(info)
                    case let .unreadChatCount(info):
                        updateUnreadChatCount(info)
                    case let .chatLastMessage(info):
                        updateChatLastMessage(info)
                    case let .chatDraftMessage(info):
                        updateChatDraftMessage(info)
                    case let .connectionState(info):
                        updateConnectionState(info)
                    default:
                        break
                }
            }
            .store(in: &subscribers)
        if let filters = try? service.getFilters() {
            logger.debug("Filling chat filter with cached ones: \(filters)")
            updateChatFolders = filters.map { filter in
                ChatFilterInfo(iconName: filter.iconName, id: filter.id, title: filter.title)
            }
            logger.trace("\(filters.count), \(updateChatFolders.count)")
        } else {
            logger.debug("There was an issue retrieving cached chat filters (maybe empty?), using empty OrderedSet")
            updateChatFolders = []
        }
        Defaults.publisher(.sidebarSize)
            .sink { value in
                withAnimation(.fastStartSlowStop()) {
                    self.sidebarSize = SidebarSize(rawValue: value.newValue) ?? .medium
                }
            }
            .store(in: &subscribers)
        SystemUtils.ncPublisher(for: .menubarCommandUpdate)
            .sink {
                switch $0.object as! MenubarAction {
                    case let .toggle(item, value):
                        switch item {
                            case .toggleArchive: self.isArchiveOpen = value
                            default: break
                        }
                    default: break
                }
            }
            .store(in: &subscribers)
        NWPathMonitor()
            .publisher(queue: nwPathMonitorQueue)
            .receive(on: RunLoop.main)
            .sink { value in
                Task {
                    switch value {
                        case .satisfied:
                            try await TdApi.shared.setNetworkType(type: .other)
                        case .unsatisfied:
                            try await TdApi.shared.setNetworkType(type: NetworkType.none)
                        case .requiresConnection:
                            try await TdApi.shared.setNetworkType(type: NetworkType.none)
                        @unknown default:
                            try await TdApi.shared.setNetworkType(type: NetworkType.none)
                    }
                }
            }
            .store(in: &subscribers)
    }
    
    func updateConnectionState(_ update: UpdateConnectionState) {
        logger.debug("UpdateConnectionState: \(update.state)")
        
        self.connectionState = update.state
    }
    
    func updateUnreadChatCount(_ update: UpdateUnreadChatCount) {
        logger.debug("UpdateUnreadChatCount")
        
        var shouldBeAdded = true
        let chatList = Storage.ChatList.from(tdChatList: update.chatList)
        let unreads = try! service.getUnreadCounters()
        
        logger.debug("Going through unreads")
        for unread in unreads where chatList == unread.chatList {
            logger.debug("Found a one to be updated")
            let newValue = UnreadCounter(
                chats: update.unreadCount,
                messages: unread.messages,
                chatList: unread.chatList
            )
            if let index = unreadCounters.firstIndex(where: { $0.chatList == chatList }) {
                unreadCounters.remove(at: index)
            }
            unreadCounters.append(newValue)
            shouldBeAdded = false
        }
        
        if shouldBeAdded {
            logger.debug("Adding a new one")
            unreadCounters.append(UnreadCounter(
                chats: update.unreadCount,
                messages: 0,
                chatList: chatList
            ))
        }
    }
    
    func updateupdateChatFolders(_ update: UpdateupdateChatFolders) {
        logger.debug("Chat filter update")
        
        withAnimation(.fastStartSlowStop()) {
            updateChatFolders = update.updateChatFolders
        }
    }

    func updateChatPosition(_ update: UpdateChatPosition) {
        updatePosition(for: update.chatId, position: update.position)
    }
    
    func updateChatDraftMessage(_ update: UpdateChatDraftMessage) {
        for position in update.positions {
            updatePosition(for: update.chatId, position: position)
        }
    }
    
    func updateChatLastMessage(_ update: UpdateChatLastMessage) {
        for position in update.positions {
            updatePosition(for: update.chatId, position: position)
        }
    }
    
    func updateNewChat(_ update: UpdateNewChat) {
        withAnimation(.fastStartSlowStop()) {
            let index = allChats.firstIndex(where: { $0.id == update.chat.id })
            if let index {
                allChats.remove(at: index)
            }
            allChats.update(with: update.chat)
        }
    }
    
    func updatePosition(for chatId: Int64, position: ChatPosition) {
        if !chatPositions.contains(where: { key, value in
            key == chatId && getPosition(from: value, chatList: position.list) == position
        }) {
            withAnimation(.fastStartSlowStop()) {
                if chatPositions[chatId] == nil {
                    chatPositions[chatId] = []
                }
                
                if let index = chatPositions[chatId]!.firstIndex(where: { $0.list == position.list }) {
                    chatPositions[chatId]!.remove(at: index)
                    chatPositions[chatId]!.append(position)
                } else {
                    chatPositions[chatId]!.append(position)
                }
            }
        }
        
    }

    deinit {
        for subscriber in subscribers {
            subscriber.cancel()
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
