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

    static let sectionDateFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }()

    static let sectionDateInCurrentWeekFormatter: NSDateFormatter =  {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE HH:mm"
        return dateFormatter
    }()

    @IBOutlet weak var sectionDateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWithMessage(message: Message) {

        let createdAt = NSDate(timeIntervalSince1970: message.createdUnixTime)
        if createdAt.isInCurrentWeek() {
            sectionDateLabel.text = ChatSectionDateCell.sectionDateInCurrentWeekFormatter.stringFromDate(createdAt)
        } else {
            sectionDateLabel.text = ChatSectionDateCell.sectionDateFormatter.stringFromDate(createdAt)
        }
    }
}

