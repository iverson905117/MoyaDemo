//
//  QueryUsers.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

extension GitHubAPI {
    struct QueryUsers: GitHubAPIBase {
        
        typealias ResponseType = MarvelResponse
        
        var parameters: [String : Any]?
        
        var path: String
        
        var method: Moya.Method {
            return .get
        }
        
        var sampleData: Data {
            return mockData
        }
        
        var task: Task {
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        }
        
        var authorizationType: AuthorizationType? {
            return .none
        }
        
        // MARK: MockableTargetType
        var stubBehavir: StubBehavior {
            return .never
        }
        
        var isStubSuccess: Bool {
            return true
        }
        
        var successFileName: String {
            return ""
        }
        
        var failureFileName: String {
            return ""
        }
        
        // MARK: RetryableTargetType
        var retryCount: Int = 5
        
        init(user: String) {
            self.path = "/users/" + "\(user)"
        }
    }
}