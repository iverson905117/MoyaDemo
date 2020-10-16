//
//  APITest.swift
//  MoyaDemo_mockTests
//
//  Created by i_vickang on 2020/10/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import XCTest
import Moya

@testable import MoyaDemo_mock

class APITest: XCTestCase {
    
    var networkService: NetworkService!
    var session: URLSession!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        networkService = NetworkService.shared
        session = URLSession(configuration: .default)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        networkService = nil
        session = nil
    }
    
    func testGithubUserApi_by_URLSession() {
        // given
        let url = URL(string: "https://api.github.com/users/iverson905117")!
        let promise = expectation(description: "Status code: 200")
        var statusCode: Int?
        var responseError: Error?
        
        // when
        let task = session.dataTask(with: url) { data, response, error in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
        }
        task.resume()
        wait(for: [promise], timeout: 5)
        
        // then
        XCTAssertNil(responseError)
        XCTAssertEqual(statusCode, 200)
    }
    
    func testGithubUserApi() {
        // given
        var target = GitHubAPI.QueryUsers(user: "iverson905117")
        target.retryCount = 0
        let promise = expectation(description: "success")
        var responseError: Error?
        var response: GitHubAPI.QueryUsers.ResponseType?
        
        // when
        networkService.request(target) { result in
            switch result {
            case .success(let user):
                response = user
            case .failure(let error):
                responseError = error
            }
            promise.fulfill()
        }
        wait(for: [promise], timeout: 5)
        
        // then
        XCTAssertNil(responseError)
        XCTAssertNotNil(response)
    }
}
