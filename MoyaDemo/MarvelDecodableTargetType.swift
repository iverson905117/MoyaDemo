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

protocol BaseResponse: Decodable {
    var code: Int { get }
    var status: String { get }
    var copyright: String { get }
}

protocol DecodableTargetType: TargetType {
    associatedtype ResponseType: BaseResponse
}

/// 自定 Moya TargetType

protocol MarvelDecodableTargetType: DecodableTargetType {}
extension MarvelDecodableTargetType {
    var publicKey: String { return "5c4a9f61a4746ba9a9060e5d7b3da067" }
    var privateKey: String { return "b7698afd7391a3c57ede85434b0a7d88b008d538" }
    var baseURL: URL { return URL(string: "https://gateway.marvel.com/v1/public")! }
    var headers: [String : String]? { return nil }
}

/// Marvel API TargetType enumeration
enum MarvelApi {
    struct QueryComics: MarvelDecodableTargetType {
        typealias ResponseType = MarvelModel
        var path: String { return "/comics" }
        var method: Moya.Method { return .get }
        var sampleData: Data { return Data() }
        var task: Task {
            let ts = "\(Date().timeIntervalSince1970)"
            let hash = "\(ts + privateKey + publicKey)".md5()
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
}
