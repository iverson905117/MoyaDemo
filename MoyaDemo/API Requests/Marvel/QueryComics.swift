//
//  QueryComics.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

/// Marvel API TargetType enumeration
extension MarvelAPI {
    struct QueryComics: MarvelAPIBase {
        
        typealias ResponseType = MarvelResponse
        
        var parameters: [String : Any]?
        
        var path: String {
            return "/comics"
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
        
        var authorizationType: AuthorizationType? {
            return .none
        }
        
        // MARK: MockableTargetType
        var stubBehavir: StubBehavior {
            return .never
        }
        
        var isStubSuccess: Bool {
            return false
        }
        
        var successFileName: String {
            return "MarvelResponseSuccess"
        }
        
        var failureFileName: String {
            return "MarvelResponseFailure"
        }
        
        // MARK: RetryableTargetType
        var retryCount: Int = 5
        
        init() {
            let ts = "\(Date().timeIntervalSince1970)"
            let hash = "\(ts + self.privateKey + self.publicKey)".md5()
            self.parameters = [
                "format": "comic",
                "formatType": "comic",
                "orderBy": "-onsaleDate",
                "dateDescriptor": "lastWeek",
                "limit": 50,
                "apikey": Marvel.publicKey,
                "ts": ts,
                "hash": hash!
            ]
        }
    }
}
