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
        case 10010: self = .tokenExpired        // 重取 token
        case 10011: self = .refreshTokenExpired // 登出
        case 10020: self = .tokenError          // 登出
        default:    self = .none                // pass
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
    private let refreshTokenService = RefreshTokenService()
    
    private init() {
        // Setup session
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 10 // timeout as seconds
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
        
        let customEndpointClosure = { (target: TargetType) -> Endpoint in
            return Endpoint(url: target.baseURL.absoluteString + target.path,
                            sampleResponseClosure: { .networkResponse(200 , target.sampleData) }, // statusCode on stub
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }
        
        // Access Token Auth pluging
        // 需設定 target 的 authorizationType
        let accessTokenPlugin = AccessTokenPlugin(tokenClosure: { _ in TokenData.token })
        
        // Setup provider
        provider = MoyaProvider(endpointClosure: customEndpointClosure,
                                stubClosure: stubClosure,
                                plugins: [accessTokenPlugin])
        
        customProvider = CustomMoyaProvider(endpointClosure: customEndpointClosure,
                                            stubClosure: stubClosure,
                                            session: session,
                                            plugins: [accessTokenPlugin])
    }
    
}

// MARK: - MoyaProvider

extension ConnectionService {
    
    // MARK: Request
    private func rxBaseRequest<TargetType: MultiTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        let target = MultiTarget(request)
        return provider.rx.request(target)
            .filterSuccessfulStatusCodes()
            .map(TargetType.ResponseType.self)
            .retryWhen({ error in
                return error.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    guard request.retryCount > attempt + 1 else {
                        print("API failure retry \(attempt + 1)...max count")
                        throw error
                    }
                    // Delay retry as seconds
                    print("API failure retry \(attempt + 1)...")
                    return Observable<Int>
                        .timer(.seconds(1), scheduler: MainScheduler.instance)
                        .take(1)
                }
            })
            .catchError { error in
                // can't decode
                // api failure
                if let error = error as? Moya.MoyaError, let body = try? error.response?.mapJSON(), let statusCode = error.response?.statusCode {
                    print("error response statusCode: \(statusCode)")
                    print("error response body: \(body)")
                }
                return .error(error)
            }
    }
    
    func request<TargetType: MultiTargetType>(_ target: TargetType, completion: ((_ result: Result<TargetType.ResponseType, Error>) -> Void)? = nil) {
        
        print("===== api: \(target.path) =======")
        
        guard reachabilityManager.isReachable else {
            print("No network...")
            completion?(.failure(ConnectionServiceError.noNetwork))
            return
        }
        
        rxBaseRequest(target)
            .flatMap { response -> Single<TargetType.ResponseType> in
                // (vic) test
                print("refreshTokenPassFlag: \(refreshTokenPassFlag)")
                if refreshTokenPassFlag {
                    print("Fake retry api success...")
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
                switch error {
                case .tokenExpired:
                    return self.refreshTokenObservable.flatMapLatest({ result -> Observable<()> in
                        switch result {
                        case .success:
                            print("Refresh token success...")
                            print("Retry request...")
                            refreshTokenPassFlag = true // (vic) test
                            return Observable.just(())
                        case .failure:
                            print("Refresh token fail...")
                            print("Logout...")
                            print(error.localizedDescription)
                            TokenData.removeData()
                            throw error
                        }
                    })
                default:
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

// MARK: Rx Refresh token
extension ConnectionService {
    enum RefreshTokenResult {
        case success
        case failure
    }
    
    func refreshTokenRequest() -> Observable<RefreshTokenResult> {
        return Observable<RefreshTokenResult>.create { [unowned self] observer -> Disposable in
            print("Start refreshTokenRequest....")
            self.rxRequest(MockAPI.RefreshToken(TokenData.refreshToken))
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

// MARK: - CustomProvider

extension ConnectionService {
    
    // MARK: Request
    @discardableResult
    func requestDecoded<T: MultiTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Cancellable? {
        
        print("===== api: \(target.path) =======")
        
        guard reachabilityManager.isReachable else {
            completion(.failure(ConnectionServiceError.noNetwork))
            return nil
        }
        
        let cancellableRequest = customProvider.requestDecoded(target, completion: { [unowned self] result in
            switch result {
            case .success(let response):
                print("response code: \(response.code)")
                let tokenError = TokenError(response.code)
                switch tokenError {
                case .none:
                    print("Token none error...\(target.path)")
                    completion(.success(response))
                case .tokenExpired:
                    // (vic) test
                    if refreshTokenPassFlag {
                        print("refreshTokenPassFlag: \(refreshTokenPassFlag)")
                        print("Fake retry api success...")
                        completion(.success(response))
                    } else {
                        print("Token expired...")
                        self.refreshTokenService.start { result in
                            switch result {
                            case .success:
                                print("Refresh token success...")
                                print("Retry request...")
                                refreshTokenPassFlag = true // (vic) test
                                self.requestDecoded(target, completion: completion)
                            case .failure(let error):
                                print("Refresh token fail...")
                                completion(.failure(error))
                            }
                        }
                    }
                default:
                    print("Token error...")
                    print("Logout...")
                    TokenData.removeData()
                    completion(.failure(tokenError))
                }
            case .failure(let error):
                if target.retryCount > 0 {
                    print("API failure retry...")
                    var target = target
                    target.retryCount -= 1
                    self.requestDecoded(target, completion: completion)
                } else {
                    print("API failure retry max count...")
                    if let error = error as? Moya.MoyaError, let body = try? error.response?.mapJSON(), let statusCode = error.response?.statusCode {
                        print("error response statusCode: \(statusCode)")
                        print("error response body: \(body)")
                    }
                    completion(.failure(error))
                }
            }
        })
        
        return cancellableRequest
    }
    
    @discardableResult
    func rxRequestDecoded<T: MultiTargetType>(_ target: T, completion: ((Result<T.ResponseType, Error>) -> Void)? = nil) -> Single<T.ResponseType> {
                
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
                cancellableRequest?.cancel()
            }
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
