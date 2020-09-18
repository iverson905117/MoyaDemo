//
//  MarvelDecodableTargetType.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

// https://developer.marvel.com/docs
 
/// 自定 Moya TargetType

protocol MarvelApiBase: MultiTargetType {
    var parameters: [String: Any]? { get }
}
extension MarvelApiBase {
    var publicKey: String { return "5c4a9f61a4746ba9a9060e5d7b3da067" }
    var privateKey: String { return "b7698afd7391a3c57ede85434b0a7d88b008d538" }
    var baseURL: URL { return URL(string: "https://gateway.marvel.com/v1/public")! }
    var headers: [String : String]? { return nil }
}

enum MarvelApi {}

/// Marvel API TargetType enumeration
extension MarvelApi {
    struct QueryComics: MarvelApiBase {
        
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
            return .delayed(seconds: 1)
        }
        
        var isStubSuccess: Bool {
            return true
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
