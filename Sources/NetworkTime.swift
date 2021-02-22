//
//  NetworkTime.swift
//  SwiftNTP
//
//  Created by 李毅 on 2021/1/31.
//

import Foundation

public class NetworkTime {
    public static var shared = NetworkTime()

    private var timeAssociations: [NetworkManager]?

    private init() {
        OperationQueue().addOperation { [weak self] in
            self?.createAssociations()
        }
    }
}

public extension NetworkTime {
    var networkDate: Date {
        Date(timeIntervalSinceNow: 0 - networkOffset)
    }

    var networkOffset: TimeInterval {
        guard let timeAssociations = timeAssociations, timeAssociations.count != 0 else {
            return 0
        }

        var timeInterval = 0.0
        var usefulCount = 0
        timeAssociations.sorted { (left, right) -> Bool in
            left.description < right.description
        }.forEach { netAssociation in
            if netAssociation.active, netAssociation.trusty {
                usefulCount += 1
                timeInterval += netAssociation.offset
            }

            if usefulCount == 8 {
                return
            }
        }

        if usefulCount > 0 {
            timeInterval = timeInterval / Double(usefulCount)
        }
        return timeInterval
    }

    func createAssociations() {
        createAssociationsWithServers(domains: ["time.apple.com"])
//        createAssociationsWithServers(domains: ["ntp.aliyun.com", "ntp1.aliyun.com", "ntp2.aliyun.com", "ntp3.aliyun.com", "ntp4.aliyun.com"])
    }

    func createAssociationsWithServers(domains: [String]) {
        timeAssociations = domains.reduce([String](), { (result, domain) -> [String] in
            result + (NetworkManager.ipAddrFromDomainName(domain) ?? [String]())
        }).map { (host) -> NetworkManager in
            NetworkManager(serverName: host)
        }

        enableAssociations()
    }
}

private extension NetworkTime {
    func enableAssociations() {
        timeAssociations?.forEach {
            $0.enable()
        }
    }

    func snoozeAssociations() {
        timeAssociations?.forEach {
            $0.snooze()
        }
    }

    func finishAssociations() {
        timeAssociations?.forEach {
            $0.finish()
        }
    }
}
