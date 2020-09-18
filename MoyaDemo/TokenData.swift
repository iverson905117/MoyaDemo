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
    
    static func removeData() {
        token = ""
        refreshToken = ""
        tokenExpiredIn = ""
    }
}
