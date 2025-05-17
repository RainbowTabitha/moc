//
//  L10nText.swift
//  
//
//  Created by Егор Яковенко on 29.10.2022.
//

import SwiftUI
import Backend
import Combine

public struct L10nText: View {
    @State public var key: String
    @State private var localized: String
    private var service: (any Service)?
    
    public init(_ key: String, service: (any Service)? = nil) {
        self.key = key
        self.localized = L10nManager.shared.getString(by: key)
        self.service = service
    }
    
    public var body: some View {
        Group {
            Text(localized)
        }
        .onReceive(
            service?.updateSubject.eraseToAnyPublisher() ?? Empty<Update, Never>().eraseToAnyPublisher()
        ) { update in
            if case .updateOption(let option) = update, option.name == "language_pack_id" {
                Task {
                    self.localized = L10nManager.shared.getString(by: key)
                }
            }
        }
    }
}
