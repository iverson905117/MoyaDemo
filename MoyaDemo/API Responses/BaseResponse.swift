//
//  BaseResponse.swift
//  MoyaDemo
//
//  Created by i_vickang on 2021/5/4.
//  Copyright © 2021 i_vickang. All rights reserved.
//

import Foundation

protocol BaseResponse: Decodable {
    var code: Int { get }
//    var status: String { get }
//    var copyright: String { get }
}


// 如果有多種 Base 的判別方式
