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

class ViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func test(_ sender: Any) {
//        queryMarvelComics()
//        queryMarvelComicsWithRx()
//        queryMarvel_DecodableTargetType()
//        queryMarvel_CustomProvider()
        queryMarvel_CustomProvider_rx()
    }

    func queryMarvelComics() {
        let provider = MoyaProvider<Marvel>()
        provider.request(.comics) { result in
            switch result {
            case .success(let response):
                do {
//                    print(try response.mapJSON())
                    let marvelModel = try JSONDecoder().decode(MarvelModel.self, from: response.data)
                    print(marvelModel)
                } catch {
                    print(error)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func queryMarvelComicsWithRx() {
        let provider = MoyaProvider<Marvel>()
        provider.rx.request(.comics)
            .filterSuccessfulStatusCodes()
            .map(MarvelModel.self)
            .subscribe(onSuccess: { MarvelModel in
                print(MarvelModel)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
    
    func queryMarvel_DecodableTargetType() {
        ConnectionService.shared.request(MarvelApi.QueryComics())
            .subscribe(onSuccess: { marvelModel in
                print(marvelModel)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
    
    func queryMarvel_CustomProvider() {
        ConnectionService.shared.requestDecoded(MarvelApi.QueryComics(), completion: { result in
            switch result {
            case .success(let model):
                print(model)
            case .failure(let error):
                print(error)
            }
        })
    }
    
    func queryMarvel_CustomProvider_rx() {
        ConnectionService.shared.rxRequestDecoded(MarvelApi.QueryComics())
            .subscribe(onSuccess: { marvelModel in
                print(marvelModel)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
}

