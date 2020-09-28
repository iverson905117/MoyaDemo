//
//  RefreshToken.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

extension MockAPI {
    struct RefreshToken: MockAPIBase {
        
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
        
        var retryCount: Int = 0
        
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
