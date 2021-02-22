//
//  NTPTimestamp.swift
//  SwiftNTP
//
//  Created by 李毅 on 2021/2/19.
//

import Foundation

/// 长时间: 64 位, 前 32 位为秒, 后 32 位为 1/32 秒的倍数
class NTPTimestamp {
    private static let JAN1970: UInt64 = 0x83AA7E80

    var seconds: UInt32 = 0
    var fraction: UInt32 = 0

    static var now: NTPTimestamp {
        var time: timeval = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&time, nil)

        let ntpTimestamp = NTPTimestamp()
        ntpTimestamp.seconds = UInt32(time.tv_sec) + UInt32(NTPTimestamp.JAN1970)
        ntpTimestamp.fraction = UInt32(Double(time.tv_usec) * 1.0e-6 * Double(1 << 32)) // 微秒转 1/32
        return ntpTimestamp
    }

    func diffSeconds(endTime: NTPTimestamp) -> Double {
        var a: Int64 = Int64(endTime.seconds) - Int64(seconds)
        var b: UInt32 = 0
        if endTime.fraction >= fraction {
            b = endTime.fraction - fraction
        } else {
            b = fraction - endTime.fraction
            b = ~b
            a -= 1
        }
        return Double(a) + Double(b) / Double(1 << 32)
    }

    func toDate() -> Date {
        let ntp1970 = NTPTimestamp()
        ntp1970.seconds = UInt32(NTPTimestamp.JAN1970)
        return Date(timeIntervalSince1970: ntp1970.diffSeconds(endTime: self))
    }
}

/// 短时间: 32 位, 前 16 位为秒, 后 16 位为 1/16 秒的倍数
class NTPShort {
    var seconds: UInt16 = 1
    var fraction: UInt16 = 0

    var value: Double {
        Double(seconds) + Double(fraction) / Double(1 << 16)
    }
}
