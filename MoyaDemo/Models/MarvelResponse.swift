//
//  MarvelResponse.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

protocol BaseResponse: Decodable {
    var code: Int { get }
//    var status: String { get }
//    var copyright: String { get }
}

struct MarvelResponse: BaseResponse {
    var code: Int
    var status: String
    var copyright: String
    let attributionText: String?
    let attributionHTML: String?
}
