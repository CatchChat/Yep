//
//  FeedFilterCell.swift
//  Yep
//
//  Created by NIX on 16/5/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedFilterCell: UITableViewCell {

    var currentOption: Option? {
        didSet {
            if let option = currentOption {
                segmentedControl.selectedSegmentIndex = option.rawValue
            }
        }
    }

    var chooseOptionAction: ((option: Option) -> Void)?

    enum Option: Int {
        case Recommended
        case Lately

        var title: String {
            switch self {
            case .Recommended:
                return NSLocalizedString("Recommended", comment: "")
            case .Lately:
                return NSLocalizedString("Lately", comment: "")
            }
        }
    }

    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.removeAllSegments()
            (0..<2).forEach({
                let option = Option(rawValue: $0)
                segmentedControl.insertSegmentWithTitle(option?.title, atIndex: $0, animated: false)
            })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        segmentedControl.selectedSegmentIndex = Option.Recommended.rawValue

        segmentedControl.addTarget(self, action: #selector(FeedFilterCell.chooseOption(_:)), forControlEvents: .ValueChanged)
    }

    @objc private func chooseOption(sender: UISegmentedControl) {

        guard let option = Option(rawValue: sender.selectedSegmentIndex) else {
            return
        }

        chooseOptionAction?(option: option)
    }
}

