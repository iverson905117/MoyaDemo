//
//  GitHubAPIBase.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/24.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

protocol GitHubAPIBase: MultiTargetType {
    var parameters: [String: Any]? { get }
}

extension GitHubAPIBase {
    var baseURL: URL { return URL(string: "https://api.github.com")! }
    var headers: [String : String]? { return nil }
}
