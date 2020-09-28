//
//  ViewController.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/4/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import UIKit
import Moya
import RxSwift

var refreshTokenPassFlag = false // (vic) test

class ViewController: UIViewController {
    
    let connectionService = ConnectionService.shared
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func test(_ sender: Any) {
//        queryMarvelComics()
//        queryMarvelComicsWithRx()
        
//        queryMarvel_MoyaProvider()
//        queryMarvel_MoyaProvider_rx()
        
//        queryMarvel_CustomProvider()
//        queryMarvel_CustomProvider_rx()
        
        queryGitHubUsers()
    }
    
    // MARK: - Mock
    
    @IBAction func firstlogin(_ sender: Any) {
        print(#function)
        connectionService.rxRequest(MockAPI.FirstLogin(account: "VicKang", password: "123456"))
            .subscribe(onSuccess: { response in
                print(response)
                TokenData.updateToken(token: response.token, tokenExpiredIn: response.tokenExpireIn, refreshToken: response.refreshToken)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func loginByToken(_ sender: Any) {
        print(#function)
        connectionService.rxRequest(MockAPI.Login(token: TokenData.token))
            .subscribe(onSuccess: { response in
                print(response)
                TokenData.updateToken(token: nil, tokenExpiredIn: nil, refreshToken: response.refreshToken)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func logout(_ sender: Any) {
        print(#function)
        TokenData.removeData()
        refreshTokenPassFlag = false
    }
    
    // MARK: - Marvel
    
    // MARK: Basic usage
    func queryMarvelComics() {
        print(#function)
        let provider = MoyaProvider<Marvel>()
        provider.request(.comics) { result in
            switch result {
            case .success(let response):
                do {
//                    print(try response.mapJSON())
                    let marvelModel = try JSONDecoder().decode(MarvelResponse.self, from: response.data)
                    print(marvelModel)
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func queryMarvelComicsWithRx() {
        print(#function)
        let provider = MoyaProvider<Marvel>()
        provider.rx.request(.comics)
            .filterSuccessfulStatusCodes()
            .map(MarvelResponse.self)
            .subscribe(onSuccess: { MarvelModel in
                print(MarvelModel)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: Moya provider
    func queryMarvel_MoyaProvider() {
        print(#function)
        connectionService.request(MarvelAPI.QueryComics(), completion: { result in
            switch result {
            case .success(let model):
                print(model)
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
    
    func queryMarvel_MoyaProvider_rx() {
        print(#function)
        connectionService.rxRequest(MarvelAPI.QueryComics())
            .subscribe(onSuccess: { marvelModel in
                print(marvelModel)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: Custom provider
    func queryMarvel_CustomProvider() {
        print(#function)
        connectionService.requestDecoded(MarvelAPI.QueryComics(), completion: { result in
            switch result {
            case .success(let model):
                print(model)
            case .failure(let error):
                print(error.localizedDescription)
            }
        })
    }
    
    func queryMarvel_CustomProvider_rx() {
        print(#function)
        connectionService.rxRequestDecoded(MarvelAPI.QueryComics())
            .subscribe(onSuccess: { model in
                print(model)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - GitHub
    func queryGitHubUsers() {
        print(#function)
        connectionService.rxRequestDecoded(GitHubAPI.QueryUsers(user: "iverson905117"))
            .subscribe(onSuccess: { model in
                print(model)
            }, onError: { error in
//                print(error)
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}

