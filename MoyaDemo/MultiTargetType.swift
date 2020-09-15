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
    var retryCount: Int { get }
}

protocol MockableTargetType {
    var stubBehavir: StubBehavior { get }
    var isStubSuccess: Bool { get }
    var successFile: String { get }
    var failureFile: String { get }
}
extension MockableTargetType {
    var successMockData: Data {
        let path = Bundle.main.path(forResource: successFile, ofType: "json")
        return FileHandle(forReadingAtPath: path!)!.readDataToEndOfFile()
    }
    var failureMockData: Data {
        let path = Bundle.main.path(forResource: failureFile, ofType: "json")
        return FileHandle(forReadingAtPath: path!)!.readDataToEndOfFile()
    }
}

protocol DecodableTargetType: TargetType {
    associatedtype ResponseType: BaseResponse
}

protocol MultiTargetType: DecodableTargetType, MockableTargetType, RetryableTargetType, AccessTokenAuthorizable {}
