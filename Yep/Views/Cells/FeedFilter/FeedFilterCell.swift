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

    var chooseOptionAction: ((_ option: Option) -> Void)?

    enum Option: Int {
        case recommended
        case lately

        var title: String {
            switch self {
            case .recommended:
                return NSLocalizedString("Recommended", comment: "")
            case .lately:
                return String.trans_titleLately
            }
        }
    }

    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.removeAllSegments()
            (0..<2).forEach({
                let option = Option(rawValue: $0)
                segmentedControl.insertSegment(withTitle: option?.title, at: $0, animated: false)
            })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        segmentedControl.selectedSegmentIndex = Option.recommended.rawValue

        segmentedControl.addTarget(self, action: #selector(FeedFilterCell.chooseOption(_:)), for: .valueChanged)
    }

    @objc fileprivate func chooseOption(_ sender: UISegmentedControl) {

        guard let option = Option(rawValue: sender.selectedSegmentIndex) else {
            return
        }

        chooseOptionAction?(option)
    }
}

