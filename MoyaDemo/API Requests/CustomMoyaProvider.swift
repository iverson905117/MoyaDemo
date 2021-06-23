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
        
        super.init(endpointClosure: endpointClosure,
                   requestClosure: requestClosure,
                   stubClosure: stubClosure,
                   callbackQueue: callbackQueue,
                   session: session,
                   plugins: plugins,
                   trackInflights: trackInflights)
    }
}

extension CustomMoyaProvider {
    
    func requestDecoded<T: MultiTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Cancellable {
        
        let target = MultiTarget(target)
        
        return request(target) { result in
//            let _ = try? result.get()
            switch result {
            case .success(let response):
                do {
                    // TODO: Log
                    print("response description: \(response.description)")
                    // ckeck status code 2xx and map to object
                    let value = try response.filterSuccessfulStatusCodes().map(T.ResponseType.self)
                    completion(.success(value))
                    return
                }
                catch let error {
                    // 1. status code not 2xx
                    // 2. map to object failure
                    if let error = error as? Moya.MoyaError,
                       let body = try? error.response?.mapJSON(),
                       let statusCode = error.response?.statusCode {
                        print("error response statusCode: \(statusCode)")
                        print("error response body: \(body)")
                        completion(.failure(error))
                        return
                    } else {
                        completion(.failure(error))
                        return
                    }
                }
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }
    
}
