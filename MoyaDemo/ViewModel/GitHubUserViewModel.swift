//
//  GitHubUserViewModel.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/10/15.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

struct GitHubUserViewModel {
    var id: Int?
    var name: String?
    
    init(model: UserResponse) {
        id = model.id
        name = model.name
    }
}
