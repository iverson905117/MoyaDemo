//
//  MockResponse.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

struct LoginResponse: BaseResponse {
    var code: Int
    var status: String
    var copyright: String
    let token: String
    let refreshToken: String
    let tokenExpireIn: String
}

struct RefreshTokenResponse: BaseResponse {
    var code: Int
    var status: String
    var copyright: String
    let token: String
    let tokenExpireIn: String
}
