//
//  Marvel.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

/// 一般使用方法

enum Marvel {
    
    static public let publicKey = "5c4a9f61a4746ba9a9060e5d7b3da067"
    static private let privateKey = "b7698afd7391a3c57ede85434b0a7d88b008d538"
    
    case comics
}

extension Marvel: TargetType {

    var baseURL: URL { return URL(string: "https://gateway.marvel.com/v1/public")! }
    
    var path: String {
        switch self {
        case .comics: return "/comics"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .comics: return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        let ts = "\(Date().timeIntervalSince1970)"
        let hash = "\(ts + Marvel.privateKey + Marvel.publicKey)".md5()
        
        switch self {
        case .comics:
          return .requestParameters(
            parameters: [
                "format": "comic",
                "formatType": "comic",
                "orderBy": "-onsaleDate",
                "dateDescriptor": "lastWeek",
                "limit": 50,
                "apikey": Marvel.publicKey,
                "ts": ts,
                "hash": hash!],
            encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
    
}
