//
//  ConnectionService.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Alamofire
import Moya
import RxSwift

enum ConnectionResponseCode: Int {
    case success             = 200
    case tokenExpired        = 10010
    case refreshTokenExpired = 10011
    case tokenError          = 10020
}

enum ConnectionServiceError {
    static let noNetwork = NSError(domain: "no.network.error",
                                   code: 0,
                                   userInfo: [NSLocalizedDescriptionKey: "noNetworkErrorMessage".localized])
}

private let isTest = ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath")

class ConnectionService {
    
    static let shared = ConnectionService()
    private var provider: MoyaProvider<MultiTarget>!
    private var customProvider: CustomMoyaProvider!
    private let reachabilityManager = ReachabilityManager.shared
    private let disposeBag = DisposeBag()
    var session: Session!
    
    private init() {
        
        // Setup session
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 10 // as seconds
        // SSL pinning ServerTrustPolicyManager ...
        session = Session(configuration: configuration,
                          startRequestsImmediately: false,
                          interceptor: self)
        
        let stubClosure = { (target: TargetType) -> StubBehavior in
            #if MOCK
            return StubBehavior.delayed(seconds: 0.1)
            #else
            return isTest ? .delayed(seconds: 0.1) : (target as! MockableTargetType).stubBehavir
            #endif
        }
        
        // Setup provider
        
        // Access Token Auth
        let token = ""
        let authPlugin = AccessTokenPlugin(tokenClosure: { _ in token })
        
        provider = MoyaProvider(stubClosure: stubClosure,
                                plugins: [authPlugin]
        )
        customProvider = CustomMoyaProvider(stubClosure: stubClosure,
                                            session: session,
                                            plugins: [authPlugin])
    }
    
    
}

// MARK: - MoyaProvider
extension ConnectionService {
    func request<TargetType: MultiTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        
        guard reachabilityManager.isReachable else {
            print("No network")
            return .error(ConnectionServiceError.noNetwork)
        }
        
        return Single<TargetType.ResponseType>.create { single in
            self.rxRequest(request)
                .subscribe(onSuccess: { response in
                    let responseCodeType = ConnectionResponseCode(rawValue: response.code)
                    // TODO: 需優化 改用 retryWhen 來重新取得 refreshToken
                    switch responseCodeType {
                    case .success:
                        single(.success(response))
                    case .tokenExpired:
                        print("Token expired")
                        self.request(request)
                            .subscribe(onSuccess: { response in
                                single(.success(response))
                            })
                            .disposed(by: self.disposeBag)
                    case .refreshTokenExpired:
                        print("RefreshToken error")
                    case .tokenError:
                        print("Token error")
                    default:
                        break
                    }
                }, onError: { error in
                    single(.error(error))
                })
                .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
    
    private func rxRequest<TargetType: MultiTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        let target = MultiTarget.init(request)
        return provider.rx.request(target)
            .filterSuccessfulStatusCodes()
            .map(TargetType.ResponseType.self)
            .asObservable()
//            .retry(5)
            .retryWhen({ (errors: Observable<Error>) in
                return errors.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    guard request.retryCount > attempt + 1 else {
                        return .error(error)
                    }
                    // Delay retry as seconds
                    return Observable<Int>
                        .timer(.seconds(1), scheduler: MainScheduler.instance)
                        .take(1)
                }
            })
            .catchError { error in
                print(error)
                return .error(error)
        }
//        .observeOn(MainScheduler.instance)
            .asSingle()
    }
}

// MARK: - CustomProvider
extension ConnectionService {
    @discardableResult
    func requestDecoded<T: MultiTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Cancellable {
        
        let cancellableRequest = customProvider.requestDecoded(target, completion: completion)
        
        if !reachabilityManager.isReachable {
            cancellableRequest.cancel()
            completion(.failure(ConnectionServiceError.noNetwork))
        }
        
        return cancellableRequest
    }
    
    @discardableResult
    func rxRequestDecoded<T: MultiTargetType>(_ target: T, completion: ((Result<T.ResponseType, Error>) -> Void)? = nil) -> Single<T.ResponseType> {
        
        guard reachabilityManager.isReachable else {
            return Single.create { single in
                single(.error(ConnectionServiceError.noNetwork))
                return Disposables.create {}
            }
        }
        
        return Single<T.ResponseType>.create { [unowned self] single in
            let cancellableRequest = self.requestDecoded(target, completion: { result in
                switch result {
                case .success(let response):
                    single(.success(response))
                case .failure(let error):
                    single(.error(error))
                }
                completion?(result)
            })
            return Disposables.create {
                cancellableRequest.cancel()
            }
        }
        .retryWhen({ (errors: Observable<Error>) in
            return errors.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                guard target.retryCount > attempt + 1 else {
                    return .error(error)
                }
                // Delay retry as seconds
                return Observable<Int>
                    .timer(.seconds(1), scheduler: MainScheduler.instance)
                    .take(1)
            }
        })
    }
}

// MARK: - RequestInterceptor
extension ConnectionService: RequestInterceptor {
    // To add defaut http header
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var modifiedURLRequest = urlRequest
//        modifiedURLRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
//        modifiedURLRequest.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        completion(.success(modifiedURLRequest))
    }
}
