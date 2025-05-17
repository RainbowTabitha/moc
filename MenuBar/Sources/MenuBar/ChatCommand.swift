//
//  ChatCommand.swift
//  
//
//  Created by Егор Яковенко on 07.10.2022.
//

import SwiftUI
import Utilities
import L10n
import Backend
import Combine

public struct ChatCommand: Commands {
    private var service: (any Service)?
    public init(service: (any Service)? = nil) {
        self.service = service
    }
    
    @State private var archiveChatList = false
    @State private var titleString: String = L10nManager.shared.getString(by: "Menubar.Chats")
    
    public var body: some Commands {
        CommandMenu(titleString) {
            Toggle("Open archive chat list", isOn: $archiveChatList.didSet {
                sendUpdate(.toggle(.toggleArchive, $0))
            })
            .keyboardShortcut("A", modifiers: [.command, .option])
            .onReceive(
                service?.updateSubject.eraseToAnyPublisher() ?? Empty<Update, Never>().eraseToAnyPublisher()
            ) { update in
                if case .updateOption(let option) = update, option.name == "language_pack_id" {
                    Task {
                        self.titleString = L10nManager.shared.getString(by: "Menubar.Chats")
                    }
                }
            }
            Divider()
            Button("Toggle chat inspector") {
                sendUpdate(.trigger(.toggleChatInspector))
            }.keyboardShortcut("I", modifiers: .command)
            Button("Toggle chat info") {
                sendUpdate(.trigger(.toggleChatInfo))
            }.keyboardShortcut("I", modifiers: [.command, .shift])
        }
    }
}
