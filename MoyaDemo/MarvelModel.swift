//
//  MarvelModel.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

struct MarvelModel: BaseResponse {
    var code: Int
    var status: String
    var copyright: String
    let attributionText: String
    let attributionHTML: String
}
