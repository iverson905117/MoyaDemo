//
//  MockApi.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

protocol MockApiBase: MultiTargetType {
    var parameters: [String: Any]? { get }
}
extension MockApiBase {
    var baseURL: URL {
        return URL(string: "https://gateway.marvel.com/v1/public")!
    }
    var headers: [String : String]? {
        return nil
    }
}

enum MockApi {}

extension MockApi {
    struct FirstLogin: MockApiBase {
        
        typealias ResponseType = LoginResponse
        
        var parameters: [String : Any]?
        
        var stubBehavir: StubBehavior {
            return .delayed(seconds: 1)
        }
        
        var isStubSuccess: Bool {
            return true
        }
        
        var successFileName: String {
            return "LoginResponseSuccess"
        }
        
        var failureFileName: String {
            return "LoginResponseFailure"
        }
        
        var retryCount: Int = 0
        
        var authorizationType: AuthorizationType? {
            .none
        }
        
        var path: String {
            return "/login"
        }
        
        var method: Moya.Method {
            return .get
        }
        
        var sampleData: Data {
            return mockData
        }
        
        var task: Task {
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        }
        
        init(account: String, password: String) {
            self.parameters = ["account": account, "password": password]
        }
    }
}

extension MockApi {
    struct Login: MockApiBase {
        
        typealias ResponseType = LoginResponse
        
        var parameters: [String : Any]?
        
        var stubBehavir: StubBehavior {
            return .delayed(seconds: 1)
        }
        
        var isStubSuccess: Bool = true
        
        var successFileName: String {
            return "LoginResponseSuccess"
        }
        
        var failureFileName: String {
            return "LoginResponseFailure"
        }
        
        var retryCount: Int = 0
        
        var authorizationType: AuthorizationType? {
            .none
        }
        
        var path: String {
            return "/login"
        }
        
        var method: Moya.Method {
            return .get
        }
        
        var sampleData: Data {
            return mockData
        }
        
        var task: Task {
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        }
        
        init(token: String) {
            self.isStubSuccess = token.isEmpty ? false : true
            self.parameters = ["token": token]
        }
    }
}

extension MockApi {
    struct RefreshToken: MockApiBase {
        
        typealias ResponseType = RefreshTokenResponse
        
        var parameters: [String : Any]?
        
        var stubBehavir: StubBehavior {
            .delayed(seconds: 1)
        }
        
        var isStubSuccess: Bool = true
        
        var successFileName: String {
            return "RefreshTokenResponseSuccess"
        }
        
        var failureFileName: String {
            return "RefreshTokenResponseFailure"
        }
        
        var retryCount: Int = 2
        
        var authorizationType: AuthorizationType? {
            return .none
        }
        
        var path: String {
            return "/token"
        }
        
        var method: Moya.Method {
            return .get
        }
        
        var sampleData: Data {
            return mockData
        }
        
        var task: Task {
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        }
        
        init(_ refreshToken: String) {
            self.isStubSuccess = refreshToken.isEmpty ? false : true
            self.parameters = ["refreshToken": refreshToken]
        }
    }
}
