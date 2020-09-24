//
//  TokenData.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

class TokenData: NSObject {
    static var token: String = ""
    static var refreshToken: String = ""
    static var tokenExpiredIn: String = ""
    
    static func updateToken(token: String?, tokenExpiredIn: String?, refreshToken: String?) {
        print("updateToken...")
        if let token = token {
            self.token = token
        }
        if let tokenExpiredIn = tokenExpiredIn {
            self.tokenExpiredIn = tokenExpiredIn
        }
        if let refreshToken = refreshToken {
            self.refreshToken = refreshToken
        }
    }
    
    static func removeData() {
        print("TokenData.removeData()...")
        token = ""
        refreshToken = ""
        tokenExpiredIn = ""
    }
}
