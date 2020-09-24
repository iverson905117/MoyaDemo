//
//  RefreshTokenService.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/23.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation

class RefreshTokenService {
    
    var completions = [(Result<RefreshTokenResponse, Error>) -> Void]()
    let lock = NSRecursiveLock()
    let queue = DispatchQueue(label: "com.fet.app.refreshToken", attributes: .concurrent)
    
    func start(completion: @escaping (Result<RefreshTokenResponse, Error>) -> Void) {
        completions.append(completion)
        
        print("Start refreshTokenRequest....")
        ConnectionService.shared.requestDecoded(MockApi.RefreshToken(TokenData.refreshToken)) { [unowned self] result in
            print("Finish refreshTokenRequest...")
            self.queue.async {
                self.lock.lock()
                print("lock...")
                if !self.completions.isEmpty {
                    self.completions.forEach { completion in
                        switch result {
                        case .success(let response):
                            completion(.success(response))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                    print("All completion done...")
                    print("completions count...\(self.completions.count)")
                    self.completions.removeAll()
                    print("Remove all completions...count: \(self.completions.count)")
                }
                self.lock.unlock()
                print("unlock...")
            }
        }
    }
    
}
