//
//  CustomMoyaProvider.swift
//  MoyaDemo
//
//  Created by 康志斌 on 2020/4/19.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

class CustomMoyaProvider: MoyaProvider<MultiTarget> {
    
    typealias Target = MultiTarget
    
    override init(endpointClosure: @escaping MoyaProvider<MultiTarget>.EndpointClosure = MoyaProvider.defaultEndpointMapping,
                  requestClosure: @escaping MoyaProvider<MultiTarget>.RequestClosure = MoyaProvider<Target>.defaultRequestMapping,
                  stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub,
                  callbackQueue: DispatchQueue? = nil,
                  session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
                  plugins: [PluginType] = [],
                  trackInflights: Bool = false) {
        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, callbackQueue: callbackQueue, session: session, plugins: plugins, trackInflights: trackInflights)
    }
}

extension CustomMoyaProvider {
    
    func requestDecoded<T: MultiTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Cancellable {
        
        let target = MultiTarget(target)
        
        return request(target) { result in
//            let a = try? result.get()
            switch result {
            case .success(let response):
                do {
                    let object = try response.filterSuccessfulStatusCodes().map(T.ResponseType.self)
                    completion(.success(object))
                }
                catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
