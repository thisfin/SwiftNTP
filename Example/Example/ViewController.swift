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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .yellow

        view.addSubview(sysClockLabel)
        view.addSubview(netClockLabel)
        view.addSubview(offsetLabel)

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
