//
//  MoyaDemo_mockTests.swift
//  MoyaDemo_mockTests
//
//  Created by i_vickang on 2020/9/23.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import XCTest
import Moya
@testable import MoyaDemo_mock

class MoyaDemo_mockTests: XCTestCase {
    
    var networkService: NetworkService!
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService.shared
        session = URLSession(configuration: .default)
    }
    
    override func tearDown() {
        networkService = nil
        session = nil
        super.tearDown()
    }
}
