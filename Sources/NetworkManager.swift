//
//  NetworkManager.swift
//  SwiftNTP
//
//  Created by 李毅 on 2021/1/31.
//

import CocoaAsyncSocket
import UIKit

public class NetworkManager: NSObject {
    public weak var delegate: NetworkManagerDelegate?
    public private(set) var server: String
    public private(set) var active: Bool = false
    public private(set) var trusty: Bool = false
    public private(set) var offset: Double = .infinity

    private var repeatingTimer: Timer?
    private var pollingIntervalIndex: Int = 0

    private var requestObject: NTPModel?
    private var responseObject: NTPModel?

    private var timerWobbleFactor: Double = 0
    private var fifoQueue: [Double] = [Double](repeating: .nan, count: 8)
    private var fifoIndex = 0

    private lazy var socket: GCDAsyncUdpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue(label: server))

    public init(serverName: String) {
        server = serverName
        super.init()
        delegate = self
        registerObservations()
    }

    private static var pollIntervals: [Double] = [2.0, 16.0, 16.0, 16.0, 16.0, 35.0, 72.0, 127.0, 258.0, 511.0, 1024.0, 2048.0, 4096.0, 8192.0, 16384.0, 32768.0, 65536.0, 131072.0]
}

extension NetworkManager: GCDAsyncUdpSocketDelegate {
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        decodePacket(data: data)
    }
}

extension NetworkManager: NetworkManagerDelegate {
    public func ntpReport() {
        fifoQueue[fifoIndex % 8] = offset
        fifoIndex += 1
        fifoIndex %= 8

        var good = 0
        var fail = 0
        var none = 0
        offset = 0.0
        for i in 0 ..< 8 {
            if fifoQueue[i].isNaN {
                none += 1
                continue
            }
            if fifoQueue[i].isInfinite || fabs(fifoQueue[i]) < 0.0001 {
                fail += 1
                continue
            }
            good += 1
            offset += fifoQueue[i]
        }

        var stdDev = 0.0
        if good > 0 || fail > 3 {
            offset = offset / Double(good)

            for i in 0 ..< 8 {
                if fifoQueue[i].isNaN {
                    continue
                }
                if fifoQueue[i].isInfinite || fabs(fifoQueue[i]) < 0.001 {
                    continue
                }
                stdDev += (fifoQueue[i] - offset) * (fifoQueue[i] - offset)
            }
            stdDev = sqrt(stdDev / Double(good))
            trusty = (good + none > 4) && (fabs(offset) < 0.050 || (fabs(offset) > 2.0 * stdDev))
        }

        if let stratum = responseObject?.stratum,
           (stratum == 1 && pollingIntervalIndex != 6) || (stratum == 2 && pollingIntervalIndex != 5) { // 层级高的话, 减少调用频率
            pollingIntervalIndex = 7 - Int(stratum)
        }
    }
}

public extension NetworkManager {
    func enable() {
        for i in 0 ..< fifoQueue.count {
            fifoQueue[i] = .nan
        }
        fifoIndex = 0

        repeatingTimer = Timer(timeInterval: TimeInterval(MAXFLOAT), repeats: true) { [weak self] _ in
            self?.queryTimeServer()
        }
        repeatingTimer?.tolerance = 1
        RunLoop.main.add(repeatingTimer!, forMode: .default)

        timerWobbleFactor = Double(Float(arc4random()) / Float(RAND_MAX) / 2 + 0.75)
        let interval = type(of: self).pollIntervals[pollingIntervalIndex] * timerWobbleFactor
        repeatingTimer?.tolerance = 5
        repeatingTimer?.fireDate = Date(timeIntervalSinceNow: interval)
        pollingIntervalIndex = 4
    }

    func snooze() {
        repeatingTimer?.fireDate = Date.distantFuture
        active = false
    }

    func finish() {
        repeatingTimer?.invalidate()
        active = false
    }

    // 单一调用
    func sendTimeQuery() {
        let requestObject = NTPModel.requestObject
        self.requestObject = requestObject
        socket.send(requestObject.toData(), toHost: server, port: 123, withTimeout: 2.0, tag: 0)
        try? socket.beginReceiving()
    }

    override var description: String {
        let stratum = String(describing: responseObject?.stratum ?? UInt8.max)
        let offset = String(format: "%5.3f", self.offset)
        let rootDispersion = String(format: "%5.3f", responseObject?.rootDispersion.value ?? 0)
        return "\(trusty ? "↑" : "↓") [\(server)] stratum=\(stratum); offset=\(offset)±\(rootDispersion)mS"
    }
}

extension NetworkManager {
    static func ipAddrFromDomainName(_ domainName: String) -> [String]? {
        let unmanagedHost = CFHostCreateWithName(nil, domainName as CFString)
        let host = unmanagedHost.takeRetainedValue()
        if !CFHostStartInfoResolution(host, .addresses, nil) {
            return nil
        }
        var nameFound: DarwinBoolean = false
        let unmanagedNTPHostAddrs = CFHostGetAddressing(host, &nameFound)
        guard nameFound.boolValue, let addrs = unmanagedNTPHostAddrs?.takeUnretainedValue() as? Array<CFData> else {
            return nil
        }

        return addrs.compactMap { (cfData) -> String? in
            GCDAsyncUdpSocket.host(fromAddress: cfData as Data)
        }
    }
}

private extension NetworkManager {
    func registerObservations() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            // Application -> Background
            self.snooze()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            // Application -> Foreground
            self.enable()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in
            // Application -> Terminate
            self.finish()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil) { _ in
            // Application -> SignificantTimeChange
            for i in 0 ..< self.fifoQueue.count {
                self.fifoQueue[i] = .nan
            }
            self.fifoIndex = 0
        }
    }

    func queryTimeServer() {
        sendTimeQuery()

        timerWobbleFactor = Double(Float(arc4random()) / Float(RAND_MAX) / 2 + 0.75)
        let interval = type(of: self).pollIntervals[pollingIntervalIndex] * timerWobbleFactor
        repeatingTimer?.fireDate = Date(timeIntervalSinceNow: interval)
    }

    func decodePacket(data: Data) {
        let ntpClientRecvTime = NTPTimestamp.now
        offset = .infinity

        guard let response = NTPModel(response: data),
              let request = requestObject,
              request.transmitTime.seconds == response.originateTime.seconds,
              request.transmitTime.fraction == response.originateTime.fraction,
              response.rootDispersion.seconds < 100,
              response.stratum > 0,
              response.mode == 4,
              response.referenceTime.diffSeconds(endTime: response.transmitTime) < 3600 else {
            return
        }

        responseObject = response

        let t41: Double = response.referenceTime.diffSeconds(endTime: ntpClientRecvTime)
        let t32: Double = response.receiveTime.diffSeconds(endTime: response.transmitTime)
        _ = t41 - t32

        let t21: Double = response.receiveTime.diffSeconds(endTime: response.originateTime)
        let t34: Double = response.transmitTime.diffSeconds(endTime: ntpClientRecvTime)
        offset = (t21 + t34) / 2

        active = true

        DispatchQueue.main.async {
            self.delegate?.ntpReport()
        }
    }
}
