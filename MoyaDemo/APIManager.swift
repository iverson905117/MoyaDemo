//
//  APIManager.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya
import RxSwift

class APIManager {
    
    static let shared = APIManager()
    private let provider = MoyaProvider<MultiTarget>()
    
    private init() {}
    
    func request<TargetType: DecodableTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        let target = MultiTarget.init(request)
        return provider.rx.request(target)
            .filterSuccessfulStatusCodes()
            .map(TargetType.ResponseType.self)
    }
}
