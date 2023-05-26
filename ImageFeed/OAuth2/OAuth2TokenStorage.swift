//
//  OAuth2Token.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 26.05.2023.
//

import UIKit

final class OAuth2TokenStorage {
    
    private let userDefaults = UserDefaults.standard
    
    var token: String?
    {
        get {
            return userDefaults.string(forKey: "token")
        }
        set {
            return userDefaults.set(newValue, forKey: "token")
        }
    }
}
