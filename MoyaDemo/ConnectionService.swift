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

enum TokenError: Error {
    case tokenExpired
    case refreshTokenExpired
    case tokenError
    case none
    
    init(_ code: Int) {
        switch code {
        case 10010: self = .tokenExpired
        case 10011: self = .refreshTokenExpired
        case 10020: self = .tokenError
        default:    self = .none
        }
    }
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
    private lazy var refreshTokenObservable = refreshTokenRequest().share()
    
    private init() {
        // Setup session
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 10 // as seconds
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        // SSL pinning ServerTrustPolicyManager ...
        session = Session(configuration: configuration,
                          startRequestsImmediately: false,
                          interceptor: self)
        
        let stubClosure = { (target: MultiTarget) -> StubBehavior in
            #if MOCK
            return StubBehavior.delayed(seconds: 1)
            #else
            return isTest ? .delayed(seconds: 1) : (target.target as! MockableTargetType).stubBehavir
            #endif
        }
        
        // Setup provider
        
        // Access Token Auth pluging
        let token = ""
        let authPlugin = AccessTokenPlugin(tokenClosure: { _ in token })
        
        provider = MoyaProvider(stubClosure: stubClosure,
                                plugins: [authPlugin])
        
        customProvider = CustomMoyaProvider(stubClosure: stubClosure,
                                            session: session,
                                            plugins: [authPlugin])
    }
    
}

// MARK: - MoyaProvider
extension ConnectionService {
    
    private func baseRequest<TargetType: MultiTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        let target = MultiTarget(request)
        return provider.rx.request(target)
            .filterSuccessfulStatusCodes()
            .map(TargetType.ResponseType.self)
            .retryWhen({ error in
                return error.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    guard request.retryCount > attempt + 1 else {
                        throw error
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
    }
    
    func request<TargetType: MultiTargetType>(_ target: TargetType, completion: ((_ result: Result<TargetType.ResponseType, Error>) -> Void)? = nil) {
        
        print(target.path)
        
        guard reachabilityManager.isReachable else {
            print("No network...")
            completion?(.failure(ConnectionServiceError.noNetwork))
            return
        }
        
        baseRequest(target)
            .flatMap { response -> Single<TargetType.ResponseType> in
                // (vic) test
                if refrshTokenPassFlag {
                    print("Retry marvel api success...")
                    return .just(response)
                }
                
                switch TokenError(response.code) {
                case .none:
                    return .just(response)
                default:
                    throw TokenError(response.code)
                }
        }
        .retryWhen { (rxError: Observable<TokenError>) -> Observable<()> in
            rxError.flatMap { error -> Observable<()> in
                if error == .tokenExpired {
                    return self.refreshTokenObservable.flatMapLatest({ result -> Observable<()> in
                        switch result {
                        case .success:
                            print("Refresh token success...")
                            print("retry request...")
                            refrshTokenPassFlag = true // (vic) test
                            return Observable.just(())
                        case .failure:
                            print("Refresh token fail...")
                            print("Logout...")
                            print(error.localizedDescription)
                            TokenData.removeData()
                            throw error
                        }})
                } else {
                    print("Logout...")
                    print(error.localizedDescription)
                    TokenData.removeData()
                    throw error
                }
            }
        }
        .subscribe(onSuccess: {
            completion?(.success($0))
        }, onError: {
            completion?(.failure($0))
        })
        .disposed(by: disposeBag)
    }
    
    func rxRequest<TargetType: MultiTargetType>(_ target: TargetType) -> Single<TargetType.ResponseType> {
        return Single<TargetType.ResponseType>.create { single -> Disposable in
            self.request(target, completion: { result in
                switch result {
                case .success(let response):
                    single(.success(response))
                case .failure(let error):
                    single(.error(error))
                }
            })
            return Disposables.create()
        }
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
            })
            return Disposables.create {
                cancellableRequest.cancel()
            }
        }
        .retryWhen({ (errors: Observable<Error>) in
            return errors.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                guard target.retryCount > attempt + 1 else {
                    throw error
                }
                // Delay retry as seconds
                return Observable<Int>
                    .timer(.seconds(1), scheduler: MainScheduler.instance)
                    .take(1)
            }}
        )
        .catchError { error in
            return .error(error)
        }
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

// MARK: - Refresh token
extension ConnectionService {
    enum RefreshTokenResult {
        case success, failure
    }
    
    func refreshTokenRequest() -> Observable<RefreshTokenResult> {
        return Observable<RefreshTokenResult>.create { [unowned self] observer -> Disposable in
            print("Start refreshTokenRequest....")
            self.rxRequest(MockApi.RefreshToken(TokenData.refreshToken))
                .asObservable()
                .map { response -> RefreshTokenResult in
                    TokenData.token = response.token
                    TokenData.tokenExpiredIn = response.tokenExpireIn
                    return response.token.isEmpty ? .failure : .success }
                .subscribe(onNext: {
                    print("sucess...\($0)")
                    observer.onNext($0)
                    observer.onCompleted()
                    print("onCompleted...")
                }, onError: { error in
                    print("failure...\(error)")
                    observer.onNext(.failure)
                    observer.onCompleted()
                    print("onCompleted...")
                })
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}
