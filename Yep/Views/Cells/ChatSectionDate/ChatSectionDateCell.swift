//
//  ChatSectionDateCell.swift
//  Yep
//
//  Created by NIX on 15/4/13.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatSectionDateCell: UICollectionViewCell {

    static let sectionDateFormatter: DateFormatter =  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let sectionDateInCurrentWeekFormatter: DateFormatter =  {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE HH:mm"
        return dateFormatter
    }()

    @IBOutlet weak var sectionDateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWithMessage(_ message: Message) {

        let createdAt = Date(timeIntervalSince1970: message.createdUnixTime)
        if createdAt.yep_isInWeekend {
            sectionDateLabel.text = ChatSectionDateCell.sectionDateInCurrentWeekFormatter.string(from: createdAt)
        } else {
            sectionDateLabel.text = ChatSectionDateCell.sectionDateFormatter.string(from: createdAt)
        }
    }
}

