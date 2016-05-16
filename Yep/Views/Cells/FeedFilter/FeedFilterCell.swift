//
//  FeedFilterCell.swift
//  Yep
//
//  Created by NIX on 16/5/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedFilterCell: UITableViewCell {

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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
