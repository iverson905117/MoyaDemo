//
//  MoyaDemo_mockTests.swift
//  MoyaDemo_mockTests
//
//  Created by i_vickang on 2020/9/23.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import XCTest
@testable import MoyaDemo_mock

class MoyaDemo_mockTests: XCTestCase {
    
    var connectionService: ConnectionService!
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        connectionService = ConnectionService.shared
        session = URLSession(configuration: .default)
    }
    
    override  func tearDown() {
        connectionService = nil
        session = nil
        super.tearDown()
    }
    
    func testGithubUserApi() {
        let url = URL(string: "https://api.github.com/users/iverson905117")!    
        let promise = expectation(description: "Status code: 200")

        // when
        let a = session.dataTask(with: url)
        let dataTask = session.dataTask(with: url) { data, response, error in
            // then
            if let error = error {
                XCTFail("Error: \(error)")
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode == 200 {
                    promise.fulfill()
                } else {
                    XCTFail("Status code: \(statusCode)")
                }
            }
        }
        dataTask.resume()
        wait(for: [promise], timeout: 5)
    }
}
