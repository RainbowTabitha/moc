//
//  TdLoginService.swift
//
//
//  Created by Егор Яковенко on 19.01.2022.
//

import TDLibKit
import Combine
import Foundation

public class TdLoginService: LoginService {
    public func getAuthorizationState() async throws -> AuthorizationState {
        return try await tdApi.getAuthorizationState()
    }
    
    private var tdApi: TdApi = .shared
    
    public var updateSubject: PassthroughSubject<Update, Never> {
        let subject = PassthroughSubject<Update, Never>()
        self.tdApi.client.run { data in
            if let update = try? JSONDecoder().decode(Update.self, from: data) {
                subject.send(update)
            }
        }
        return subject
    }

    public func resendAuthCode() async throws {
        try await tdApi.resendAuthenticationCode(reason: .resendCodeReasonUserRequest)
    }

    public func checkAuth(phoneNumber: String) async throws {
        try await tdApi.setAuthenticationPhoneNumber(
            phoneNumber: phoneNumber,
            settings: nil
        )
    }

    public init() {}

    public func checkAuth(code: String) async throws {
        try await tdApi.checkAuthenticationCode(code: code)
    }

    public func checkAuth(password: String) async throws {
        try await tdApi.checkAuthenticationPassword(password: password)
    }
    
    public func getCountries() async throws -> [CountryInfo] {
        return try await tdApi.getCountries().countries
    }
    
    public func getCountryCode() async throws -> String {
        return try await tdApi.getCountryCode().text
    }

    public func requestQrCodeAuth() async throws {
        try await tdApi.requestQrCodeAuthentication(otherUserIds: nil)
    }
}
