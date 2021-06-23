//
//  NetworkService.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Alamofire
import Moya
import RxSwift

/// API response error
enum BackendError: Error {
    case tokenExpired
    case refreshTokenExpired
    case tokenError
    case unknow
    
    init(_ code: Int) {
        switch code {
        case 10010: self = .tokenExpired        // 重取 token
        case 10011: self = .refreshTokenExpired // 登出
        case 10020: self = .tokenError          // 登出
        default:    self = .unknow
        }
    }
}

enum NetworkServiceError: Error {
    case noNetworkReachable
}

private let isTest = ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath")

class NetworkService {
    
    static let shared = NetworkService()
    private let disposeBag = DisposeBag()
    
    private var provider: MoyaProvider<MultiTarget>!
    private var customProvider: CustomMoyaProvider!
    
    private let reachabilityManager = ReachabilityManager.shared

    var session: Session!
    
    private lazy var refreshTokenApi = refreshTokenRequest().share()
    private let refreshTokenService = RefreshTokenService()
    
//    let monitor = ClosureEventMonitor()
    
    private init() {
        
        // MARK: Setup endpointClosure
        let endpointClosure = { (target: TargetType) -> Endpoint in
            return Endpoint(url: target.baseURL.absoluteString + target.path,
                            sampleResponseClosure: { .networkResponse(200 , target.sampleData) }, // statusCode on stub
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }
        
        // MARK: Setup stubClosure
        let stubClosure = { (target: MultiTarget) -> StubBehavior in
            #if MOCK
            return StubBehavior.delayed(seconds: 1)
            #else
            return isTest ? .delayed(seconds: 1) : (target.target as! MockableTargetType).stubBehavior
            #endif
        }
        
        // MARK: Setup requestClosure
        let requestClosure = { (endpoint: Endpoint, requestResultClosure: (Result<URLRequest, MoyaError>) -> Void) in
            do {
                let urlRequest = try endpoint.urlRequest()
                requestResultClosure(.success(urlRequest))
            } catch {
                requestResultClosure(.failure(error as! MoyaError))
            }
        }
        
        // MARK: Setup accessTokenPluging
        // Access Token Auth pluging
        // 需設定 target 的 authorizationType
        let accessTokenPlugin = AccessTokenPlugin(tokenClosure: { _ in TokenData.token })
        
        // MARK: Setup SSL pinning
//        let prod = URLComponents(string: HardCode.APIEnvironment.production.baseURL)?.host ?? "prod"
//        let stage = URLComponents(string: HardCode.APIEnvironment.stage.baseURL)?.host ?? "stage"
//        let dev = URLComponents(string: HardCode.APIEnvironment.dev.baseURL)?.host ?? "dev"
//
//        let cerBase64 = ""
//
//        guard
//            let certificateData = Data(base64Encoded: cerBase64, options: []),
//            let certificate = SecCertificateCreateWithData(nil, certificateData as CFData)
//        else { return }
//
//        let expiredDate = "2021/11/25 00:00:00".date(with: "yyyy/MM/dd HH:mm:ss", timeZoneSecondsFromGMT: 8 * 60 * 60)
//
//        let prodCertificatesTrustEvaluator: ServerTrustEvaluating = (expiredDate! > Date() && !SwifterSwift.isInDebuggingMode) ? PinnedCertificatesTrustEvaluator(certificates: [certificate]) : DisabledTrustEvaluator()
//
//        let evaluators: [String: ServerTrustEvaluating] = [
//            prod: prodCertificatesTrustEvaluator,
//            stage: DisabledTrustEvaluator(),
//            dev: DisabledTrustEvaluator()
//        ]
        
        // MARK: Setup session
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 10 // timeout as seconds
        configuration.timeoutIntervalForResource = configuration.timeoutIntervalForRequest
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        session = Session(configuration: configuration
                          /*serverTrustManager: ServerTrustManager(evaluators: evaluators)*/
                          /*startRequestsImmediately: false,*/
                          /*interceptor: self*/
                          /*eventMonitors: [monitor]*/)
        
        // MARK: Initial provider
        provider = MoyaProvider(endpointClosure: endpointClosure,
                                requestClosure: requestClosure,
                                stubClosure: stubClosure,
                                plugins: [accessTokenPlugin])
        
        customProvider = CustomMoyaProvider(endpointClosure: endpointClosure,
                                            requestClosure: requestClosure,
                                            stubClosure: stubClosure,
                                            session: session,
                                            plugins: [accessTokenPlugin])
    }
    
}

// MARK: - MoyaProvider request

extension NetworkService {
    
    private func rxBaseRequest<TargetType: MultiTargetType>(_ request: TargetType) -> Single<TargetType.ResponseType> {
        let target = MultiTarget(request)
        return provider.rx.request(target)
            .filterSuccessfulStatusCodes()
            .map(TargetType.ResponseType.self)
            .retryWhen({ error in
                return error.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    guard request.retryCount > attempt + 1 else {
                        print("API failure retry max count: \(attempt + 1)")
                        throw error
                    }
                    // Delay retry as seconds
                    print("API failure retry count: \(attempt + 1)...")
                    return Observable<Int>.timer(.seconds(1), scheduler: MainScheduler.instance).take(1)
                }
            })
            .catchError { error in
                // 1. status code not 2xx
                // 2. map to object failure
                if let error = error as? Moya.MoyaError,
                   let body = try? error.response?.mapJSON(),
                   let statusCode = error.response?.statusCode {
                    print("error response statusCode: \(statusCode)")
                    print("error response body: \(body)")
                }
                return .error(error)
            }
    }
    
    func request<TargetType: MultiTargetType>(_ target: TargetType, completion: ((_ result: Result<TargetType.ResponseType, Error>) -> Void)? = nil) {
        
        print("===== api: \(target.path) =======")
        
        guard reachabilityManager.isReachable else {
            completion?(.failure(NetworkServiceError.noNetworkReachable))
            return
        }
        
        rxBaseRequest(target)
            .flatMap { response -> Single<TargetType.ResponseType> in
                
                print("API success response code: \(response.code)")
                
                // (vic) test
                print("refreshTokenPassFlag: \(refreshTokenPassFlag)")
                if refreshTokenPassFlag {
                    print("Fake retry api success...")
                    return .just(response)
                }
                // (vic) test
                
                if response.code == 200 {
                    // api response code == 200 --> success
                    return .just(response)
                } else {
                    // api response code != 200 --> failure
                    throw BackendError(response.code)
                }
            }
            .retryWhen { (rxError: Observable<BackendError>) -> Observable<Void> in
                rxError.flatMap { error -> Observable<Void> in
                    
                    switch error {
                    case .tokenExpired:
                        return self.refreshTokenApi.flatMapLatest({ result -> Observable<Void> in
                            switch result {
                            case .success:
                                print("Refresh token success...")
                                print("Retry request...")
                                
                                // (vic) test
                                refreshTokenPassFlag = true
                                // (vic) test
                                
                                return Observable.just(())
                                
                            case .failure(let error):
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

// MARK: - CustomProvider request

extension NetworkService {
    
    @discardableResult
    func requestDecoded<T: MultiTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResponseType, Error>) -> Void) -> Cancellable? {
        
        print("===== api: \(target.path) =======")
        
        guard reachabilityManager.isReachable else {
            completion(.failure(NetworkServiceError.noNetworkReachable))
            return nil
        }
        
        let request = customProvider.requestDecoded(target, completion: { [unowned self] result in
            switch result {
            case .success(let response):
                
                print("API success response code: \(response.code)")
                
                if response.code == 200 {
                    
                    completion(.success(response))
                    return
                    
                } else {
                    
                    // backendError appear when response success
                    let beckendError = BackendError(response.code)
                    
                    switch beckendError {
                    case .tokenExpired:
                        
                        // (vic) test
                        if refreshTokenPassFlag {
                            print("refreshTokenPassFlag: \(refreshTokenPassFlag)")
                            print("Fake retry api success...")
                            completion(.success(response))
                            return
                        }
                        // (vic) test
                        
                        print("Token expired...")
                        self.refreshTokenService.start { result in
                            switch result {
                            case .success:
                                
                                print("Refresh token success...")
                                
                                // (vic) test
                                refreshTokenPassFlag = true
                                // (vic) test
                                
                                print("Retry request...")
                                self.requestDecoded(target, completion: completion)
                                return
                                
                            case .failure(let error):
                                
                                print("Refresh token fail...")
                                completion(.failure(error))
                                return
                            }
                        }
                    default:
                        print("BeckendError: \(beckendError)")
                        print("Logout...")
                        TokenData.removeData()
                        completion(.failure(beckendError))
                        return
                    }
                
                }
            case .failure(let error):
                // MARK: Retry
                if target.retryCount > 0 {
                    print("API failure retry...")
                    var target = target
                    target.retryCount -= 1
                    self.requestDecoded(target, completion: completion)
                    return
                } else {
                    print("API failure retry max count...")
                    completion(.failure(error))
                    return
                }
            }
        })
        
        return request
    }
    
    @discardableResult
    func rxRequestDecoded<T: MultiTargetType>(_ target: T, completion: ((Result<T.ResponseType, Error>) -> Void)? = nil) -> Single<T.ResponseType> {
                
        return Single<T.ResponseType>.create { [unowned self] single in
            let cancellableRequest = self.requestDecoded(target, completion: { result in
                completion?(result)
                switch result {
                case .success(let value):
                    single(.success(value))
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
extension NetworkService: RequestInterceptor {
    // To add default http header
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var modifiedURLRequest = urlRequest
//        modifiedURLRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
//        modifiedURLRequest.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        completion(.success(modifiedURLRequest))
    }
}

// MARK: - Rx Refresh token
extension NetworkService {
    enum RefreshTokenResult {
        case success
        case failure(error: Error)
    }
    
    func refreshTokenRequest() -> Observable<RefreshTokenResult> {
        return Observable<RefreshTokenResult>.create { [unowned self] observer -> Disposable in
            print("Start refreshTokenRequest....")
            self.rxRequest(MockAPI.RefreshToken(TokenData.refreshToken))
                .asObservable()
                .map { response -> RefreshTokenResult in
                    TokenData.token = response.token
                    TokenData.tokenExpiredIn = response.tokenExpireIn
                    return response.token.isEmpty ? .failure(error: BackendError(response.code)) : .success }
                .subscribe(onNext: {
                    print("sucess...\($0)")
                    observer.onNext($0)
                    observer.onCompleted()
                    print("onCompleted...")
                }, onError: { error in
                    print("failure...\(error)")
                    observer.onNext(.failure(error: error))
                    observer.onCompleted()
                    print("onCompleted...")
                })
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}
