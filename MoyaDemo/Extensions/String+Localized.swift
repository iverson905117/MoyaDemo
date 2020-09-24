//
//  String+Localized.swift
//  MoyaDemo
//
//  Created by i_vickang on 2020/9/15.
//  Copyright © 2020 i_vickang. All rights reserved.
//

import UIKit

extension String {
    var localized: String {
        get {
            return NSLocalizedString(self, comment: self)
        }
    }
}
