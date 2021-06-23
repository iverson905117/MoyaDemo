//
//  FirstLogin.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

extension MockAPI {
    struct FirstLogin: MockAPIBase {
        
        typealias ResponseType = LoginResponse
        
        var parameters: [String : Any]?
        
        var stubBehavior: StubBehavior {
            return .never
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
