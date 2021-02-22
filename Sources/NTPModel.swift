//
//  NTPModel.swift
//  SwiftNTP
//
//  Created by 李毅 on 2021/2/18.
//

import Foundation

class NTPModel {
    var leapIndicator: UInt8 = 0
    var versionNumber: UInt8 = 4
    var mode: UInt8 = 0
    var stratum: UInt8 = 0
    var poll: UInt8 = 0
    var precision: Int8 = 0
    var rootDelay: NTPShort = NTPShort()
    var rootDispersion: NTPShort = NTPShort()
    var referenceID: UInt32 = 0
    var referenceTime: NTPTimestamp = NTPTimestamp()
    var originateTime: NTPTimestamp = NTPTimestamp()
    var receiveTime: NTPTimestamp = NTPTimestamp()
    var transmitTime: NTPTimestamp = NTPTimestamp()

    init() {
    }

    init?(response data: Data) {
        let wireData = data.withUnsafeBytes({ (pointer) -> [UInt32] in
            if let address = pointer.baseAddress, pointer.count > 0, pointer.count % 4 == 0 {
                let ptr = address.assumingMemoryBound(to: UInt32.self)
                let buffer = UnsafeBufferPointer(start: ptr, count: pointer.count / 4)
                return Array<UInt32>(buffer)
            }
            return [UInt32]()
        }).map {
            UInt32(bigEndian: $0)
        }

        if wireData.count < 12 {
            return nil
        }

        leapIndicator = UInt8(wireData[0] >> 30 & 0x03)
        versionNumber = UInt8(wireData[0] >> 27 & 0x07)
        mode = UInt8(wireData[0] >> 24 & 0x07)
        stratum = UInt8(wireData[0] >> 16 & 0xFF)
        poll = UInt8(wireData[0] >> 8 & 0xFF)
        precision = Int8(bitPattern: UInt8(wireData[0] & 0xFF)) // 负数转换
        rootDelay.seconds = UInt16(wireData[1] >> 16)
        rootDelay.fraction = UInt16(wireData[1] & UInt32(UInt8.max))
        rootDispersion.seconds = UInt16(wireData[2] >> 16)
        rootDispersion.fraction = UInt16(wireData[2] & UInt32(UInt8.max))
        referenceID = UInt32(wireData[3])
        referenceTime.seconds = UInt32(wireData[4])
        referenceTime.fraction = UInt32(wireData[5])
        originateTime.seconds = UInt32(wireData[6])
        originateTime.fraction = UInt32(wireData[7])
        receiveTime.seconds = UInt32(wireData[8])
        receiveTime.fraction = UInt32(wireData[9])
        transmitTime.seconds = UInt32(wireData[10])
        transmitTime.fraction = UInt32(wireData[11])
    }
}

// 00 100 011 00000000 00000100 11111010
// 00 100 100 00000010 00000100 11100111
extension NTPModel {
    static var requestObject: NTPModel {
        let obj = NTPModel()
        obj.versionNumber = 4
        obj.mode = 3
        obj.poll = 4
        obj.precision = -6
        obj.transmitTime = NTPTimestamp.now
        return obj
    }

//    100 011 00000000 00000100 11111010

    func toData() -> Data {
        let data = NSMutableData()
        var line0 = (UInt32(leapIndicator) << 30)
        line0 = line0 | (UInt32(versionNumber) << 27)
        line0 = line0 | (UInt32(mode) << 24)
        line0 = line0 | (UInt32(stratum) << 16)
        line0 = line0 | (UInt32(poll) << 8)
        line0 = line0 | UInt32(UInt8(bitPattern: precision))
        var line0be = UInt32(line0).bigEndian
        data.append(&line0be, length: 4)
        var line1 = UInt32(rootDelay.seconds << 16 | rootDelay.fraction).bigEndian
        data.append(&line1, length: 4)
        var line2 = UInt32(rootDispersion.seconds << 16 | rootDispersion.fraction).bigEndian
        data.append(&line2, length: 4)
        var line3 = referenceID.bigEndian
        data.append(&line3, length: 4)
        var line4 = referenceTime.seconds.bigEndian
        data.append(&line4, length: 4)
        var line5 = referenceTime.fraction.bigEndian
        data.append(&line5, length: 4)
        var line6 = originateTime.seconds.bigEndian
        data.append(&line6, length: 4)
        var line7 = originateTime.fraction.bigEndian
        data.append(&line7, length: 4)
        var line8 = receiveTime.seconds.bigEndian
        data.append(&line8, length: 4)
        var line9 = receiveTime.fraction.bigEndian
        data.append(&line9, length: 4)
        var line10 = transmitTime.seconds.bigEndian
        data.append(&line10, length: 4)
        var line11 = transmitTime.fraction.bigEndian
        data.append(&line11, length: 4)
        return data as Data
    }
}

/*
 Quote from jbenet/ios-ntp
 https://tools.ietf.org/html/rfc5905
 https://tools.ietf.org/id/draft-reilly-ntp-bcp-01.html
 */

/*
 ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
 │  NTP Timestamp Structure                                                                         │
 │                                                                                                  │
 │   0                   1                   2                   3                                  │
 │   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1                                │
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | LI| VN  | Mode| Stratum       | Poll          | Precision     |                               │
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Root Delay                                                    │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Root Dispersion                                               │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Reference ID                                                  │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Reference Timestamp (64)                              Seconds │                               |
 │  +                                               ----------------+                               │
 │  |                                                      Fraction │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Origin Timestamp (64)                                 Seconds │                               |
 │  +                                               ----------------+                               │
 │  |                                                      Fraction │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Receive Timestamp (64)                                Seconds │                               |
 │  +                                               ----------------+                               │
 │  |                                                      Fraction │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Transmit Timestamp (64)                               Seconds │                               |
 │  +                                               ----------------+                               │
 │  |                                                      Fraction │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  | Authenticator (optional 96)                                   │                               |
 │  |                                                               │                               |
 │  |                                                               │                               |
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │                                                                                                  │
 └──────────────────────────────────────────────────────────────────────────────────────────────────┘

 LI (Leap Indicator): 闰秒标识器, 长度为 2 Bits, 用来预警最近一分钟插入 1s 或者删除 1s.
 LI    Value    含义
 00    0        无预告
 01    1        最近一分钟有 61s
 10    2        最近一分钟有 59s
 11    3        警告状态(时钟未同步)

 VN (Version Number): 版本号, 长度为 3 Bits, 目前最新的版本是 4, 向下兼容指定于 RFC 1305 的版本 3.

 Mode: 工作模式, 长度为 3 Bits.
 点对点模式下, 客户端请求时设置此字段为 3, 服务器应答时设置此字段为 4.
 广播模式下, 服务器应答设置此字段为 5.
 Mode   Value   含义
 000    0       保留
 001    1       主动对称模式
 010    2       被动对称模式
 011    3       客户端模式
 100    4       服务器模式
 101    5       广播或组播模式
 110    6       NTP控制报文
 111    7       预留给内部使用

 Stratum: 系统时钟的层数, 长度为 8 Bits, 取值范围 1~16, 定义时钟的准确度. 层数为 1 的时钟准确度最高, 准确度从 1 到 16 依次递减, 阶层的上限为15, 层数为 16的时钟处于未同步状态, 不能作为参考时钟.
    NTP 获得 UTC 的时间来源可以是原子钟, 天文台, 卫星, 也可以从Internet上获取.
    stratum-0 是高精度计时设备, 例如原子钟 (如铯, 铷), GPS时钟或其他无线电时钟. 它们生成非常精确的脉冲秒信号, 触发所连接计算机上的中断和时间戳. 也称为参考 (基准) 时钟.
    stratum-1 是与 stratum-0 设备相连, 在几微秒误差内同步系统时钟的计算机.
    时间是按 NTP 服务器的等级传播. 按照距离外部 UTC 源的远近将所有服务器归入不同的 Stratum (层) 中. Stratum-1 在顶层, 有外部 UTC 接入, 而Stratum-2 则从 Stratum-1 获取时间, Stratum-3 从 Stratum-2 获取时间, 以此类推, 但 Stratum 层的总数限制在15以内. 所有这些服务器在逻辑上形成阶梯式的架构并相互连接, 而 Stratum-1 的时间服务器是整个系统的基础.
 stratum    含义
 0          未指定或者难以获得
 1          主要参考(如: 无线电时钟,校正的原子时钟)
 2~15       第二参考(Via NTP)
 16         未同步状态, 不能作为参考时钟

 Poll: 轮询间隔时间, 长度为 8 Bits, 两个连续NTP报文之间的时间间隔, 用 2 的幂来表示, 比如值为 6 表示最小间隔为 2^6 = 64s.

 Precision: 系统时钟的精度, 长度为 8 Bits, 用 2 的幂来表示, 比如 50Hz(20ms)或者60Hz(16.67ms) 可以表示成值 -5 (2^-5 = 0.03125s = 31.25ms).

 Root Delay: 本地到主参考时钟源的往返时间, 长度为 32 Bits, 有 15～16 位小数部分的无符号定点小数.

 Root Dispersion: 系统时钟相对于主参考时钟的最大误差, 长度为 32 Bits, 有 15～16 位小数部分的无符号定点小数.

 Reference Identifier: 参考时钟源的标识, 长度为 32 Bits.

 Reference Timestamp: 系统时钟最后一次被设定或更新的时间, 长度为 64 Bits, 无符号定点数, 前 32 Bits 表示整数部分, 后 32 Bits 表示小数部分, 理论分辨率 2^−32s.
 Originate Timestamp: NTP请求报文离开发送端时发送端的本地时间, 长度为 64 Bits.
 Receive Timestamp: NTP请求报文到达接收端时接收端的本地时间, 长度为 64 Bits.
 Transmit Timestamp: 应答报文离开应答者时应答者的本地时间, 长度为 64 Bits.
    前 32 位表示 1900 年开始的秒, 后 23 位表示秒后面的精度 2 的 32 次方分之一秒

 Authenticator(Optional): 验证信息, 长度为 96 Bits, (可选信息), 当实现了 NTP 认证模式时, 主要标识符和信息数字域就包括已定义的信息认证代码 (MAC) 信息.

 ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
 │  NTP Timestamp Structure                                                                         │
 │                                                                                                  │
 │   0                   1                   2                   3                                  │
 │   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1                                │
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  |  Seconds                                                      |                               │
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │  |  Seconds Fraction (0-padded)  |       |       |       |       | <-- 4294967296 = 1 second     │
 │  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               │
 │                  |               |       |   |   |               |                               │
 │                  |               |       |   |   |              233 picoseconds                  │
 │                  |               |       |   | 59.6 nanoseconds (mask = 0xffffff00)              │
 │                  |               |       |  238 nanoseconds (mask = 0xfffffc00)                  │
 │                  |               |      0.954 microsecond (mask = 0xfffff000)                    │
 │                  |             15.3 microseconds (mask = 0xffff0000)                             │
 │                 3.9 milliseconds (mask = 0xff000000)                                             │
 │                                                                                                  │
 └──────────────────────────────────────────────────────────────────────────────────────────────────┘
  */
