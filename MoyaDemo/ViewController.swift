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

var refrshTokenPassFlag = false // (vic) test

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
        
        queryMarvel_CustomProvider()
//        queryMarvel_CustomProvider_rx()
    }
    
    @IBAction func firstlogin(_ sender: Any) {
        connectionService.rxRequest(MockApi.FirstLogin(account: "VicKang", password: "123456"))
            .subscribe(onSuccess: { [unowned self] response in
                print(response)
                TokenData.token = response.token
                TokenData.refreshToken = response.refreshToken
                TokenData.tokenExpiredIn = response.tokenExpireIn
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func loginByToken(_ sender: Any) {
        connectionService.rxRequest(MockApi.Login(token: TokenData.token))
            .subscribe(onSuccess: { response in
                print(response)
                TokenData.refreshToken = response.refreshToken
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func logout(_ sender: Any) {
        print("Logout")
        TokenData.removeData()
        refrshTokenPassFlag = false
    }
    
    // MARK: -
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
    
    // MARK: -
    func queryMarvel_MoyaProvider() {
        print(#function)
        connectionService.request(MarvelApi.QueryComics(), completion: { result in
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
        connectionService.rxRequest(MarvelApi.QueryComics())
            .subscribe(onSuccess: { marvelModel in
                print(marvelModel)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: -
    func queryMarvel_CustomProvider() {
        print(#function)
        connectionService.requestDecoded(MarvelApi.QueryComics(), completion: { result in
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
        connectionService.rxRequestDecoded(MarvelApi.QueryComics())
            .subscribe(onSuccess: { marvelModel in
                print(marvelModel)
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}

