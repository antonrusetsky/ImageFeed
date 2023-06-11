//
//  OAuth2Token.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 26.05.2023.
//

import UIKit
import SwiftKeychainWrapper

final class OAuth2TokenStorage {

    private let keyChainStorage = KeychainWrapper.standard

    var token: String? {
        get {
            keyChainStorage.string(forKey: .tokenKey)
        }
        set {
            if let token = newValue {
                keyChainStorage.set(token, forKey: .tokenKey)
            } else {
                keyChainStorage.removeObject(forKey: .tokenKey)
            }
        }
    }
    
    func deleteToken() {
        keyChainStorage.remove(forKey: "bearerToken")
    }
}

extension String {
    static let tokenKey = "bearerToken"
}
