//
//  MultiTargetType.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/15.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import Foundation
import Moya

protocol RetryableTargetType {
    var retryCount: Int { get set }
}

protocol MockableTargetType {
    var stubBehavir: StubBehavior { get }
    var isStubSuccess: Bool { get }
    var successFileName: String { get }
    var failureFileName: String { get }
}
extension MockableTargetType {
    var successMockData: Data {
        let path = Bundle.main.path(forResource: successFileName, ofType: "json")
        return FileHandle(forReadingAtPath: path!)!.readDataToEndOfFile()
    }
    var failureMockData: Data {
        let path = Bundle.main.path(forResource: failureFileName, ofType: "json")
        return FileHandle(forReadingAtPath: path!)!.readDataToEndOfFile()
    }
    var mockData: Data {
        return isStubSuccess ? successMockData : failureMockData
    }
}

protocol DecodableTargetType {
    associatedtype ResponseType: BaseResponse
}

protocol MultiTargetType: TargetType, DecodableTargetType, MockableTargetType, RetryableTargetType, AccessTokenAuthorizable {}
