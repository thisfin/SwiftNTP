//
//  NSDate+NetworkTime.swift
//  SwiftNTP
//
//  Created by 李毅 on 2021/1/31.
//

import Foundation

public extension Date {
    var timeIntervalSinceNetworkDate: TimeInterval {
        timeIntervalSince(type(of: self).networkDate())
    }

    static func timeIntervalSinceNetworkDate() -> TimeInterval {
        Date().timeIntervalSinceNetworkDate
    }

    static func networkDate() -> Date {
        NetworkTime.shared.networkDate
    }
}
