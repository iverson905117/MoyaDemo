//
//  ViewModelTest.swift
//  MoyaDemo_mockTests
//
//  Created by i_vickang on 2020/10/16.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import XCTest
import Moya
@testable import MoyaDemo_mock

class ViewModelTest: XCTestCase {

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
    
    func testGithubUserViewModel() {
        // given
        let target = GitHubAPI.QueryUsers(user: "iverson905117")
        var viewModel: GitHubUserViewModel?
        let promise = expectation(description: "Test GithubUserViewModel")
        
        // when
        networkService.request(target) { result in
            if case let .success(user) = result {
                viewModel = GitHubUserViewModel(model: user)
            }
//            sleep(5)
            promise.fulfill()
        }
//        wait(for: [promise], timeout: 3)
        waitForExpectations(timeout: 3) { error in
            if let error = error {
                XCTFail("timeout error: \(error.localizedDescription)")
            }
        }
        
        // then
        XCTAssertEqual(viewModel?.id, 22541825)
        XCTAssertEqual(viewModel?.name, "康志斌")
    }

}
