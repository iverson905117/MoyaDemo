//
//  MockAPIBase.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

protocol MockAPIBase: MultiTargetType {
    var parameters: [String: Any]? { get }
}

extension MockAPIBase {
    var baseURL: URL {
        return URL(string: "https://gateway.marvel.com/v1/public")!
    }
    var headers: [String : String]? {
        return nil
    }
}
