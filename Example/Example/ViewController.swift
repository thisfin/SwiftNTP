//
//  ViewController.swift
//  Example
//
//  Created by 李毅 on 2021/2/22.
//

import SwiftNTP
import UIKit

class ViewController: UIViewController {
    private let networkTime = NetworkTime.shared
    private lazy var sysClockLabel = UILabel(frame: CGRect(x: 10, y: 100, width: UIScreen.main.bounds.width - 20, height: 50))
    private lazy var netClockLabel = UILabel(frame: CGRect(x: 10, y: 150, width: UIScreen.main.bounds.width - 20, height: 50))
    private lazy var offsetLabel = UILabel(frame: CGRect(x: 10, y: 200, width: UIScreen.main.bounds.width - 20, height: 50))
    private lazy var checkLabel = UILabel(frame: CGRect(x: 10, y: 250, width: UIScreen.main.bounds.width - 20, height: 50))

    private lazy var manager: NetworkManager = NetworkManager(serverName: NetworkManager.ipAddrFromDomainName("time.apple.com")?.first ?? "")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .yellow

        view.addSubview(sysClockLabel)
        view.addSubview(netClockLabel)
        view.addSubview(offsetLabel)
        view.addSubview(checkLabel)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(timeCheck(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        checkLabel.isUserInteractionEnabled = true
        checkLabel.addGestureRecognizer(tapGestureRecognizer)

        checkLabel.text = "default"
        checkLabel.layer.borderWidth = 1
        checkLabel.layer.cornerRadius = 3

        let repeatingTimer = Timer(fire: Date(timeIntervalSinceNow: 1), interval: 1, repeats: true) { [weak self] _ in
            guard let `self` = self else {
                return
            }

            self.sysClockLabel.text = "System Clock: \(Date())"
            self.netClockLabel.text = "Network Clock: \(self.networkTime.networkDate)"
            self.offsetLabel.text = "Clock Offet: \(String(format: "%5.3f", self.networkTime.networkOffset * 1000.0))"
        }
        RunLoop.current.add(repeatingTimer, forMode: .default)
    }
}

extension ViewController: NetworkManagerDelegate {
    func ntpReport() {
        checkLabel.text = "System ahead by: \(String(format: "%5.3f", manager.offset * 1000.0)) mSec"
        print(manager.description)
    }
}

@objc private extension ViewController {
    func timeCheck(_ sender: Any) {
        manager.delegate = self
        manager.sendTimeQuery()
    }
}
