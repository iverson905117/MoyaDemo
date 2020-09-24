//
//  MarvelAPIBase.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

protocol MarvelAPIBase: MultiTargetType {
    var parameters: [String: Any]? { get }
}

extension MarvelAPIBase {
    var publicKey: String { return "5c4a9f61a4746ba9a9060e5d7b3da067" }
    var privateKey: String { return "b7698afd7391a3c57ede85434b0a7d88b008d538" }
    var baseURL: URL { return URL(string: "https://gateway.marvel.com/v1/public")! }
    var headers: [String : String]? { return nil }
}

