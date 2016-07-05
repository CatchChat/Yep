//
//  Message+Yep.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

private let sectionDateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle
    dateFormatter.timeStyle = .ShortStyle
    return dateFormatter
}()

private let sectionDateInCurrentWeekFormatter: NSDateFormatter =  {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "EEEE HH:mm"
    return dateFormatter
}()

extension Message {

    var sectionDateString: String {
        let createdAt = NSDate(timeIntervalSince1970: createdUnixTime)
        if createdAt.isInCurrentWeek() {
            return sectionDateInCurrentWeekFormatter.stringFromDate(createdAt)
        } else {
            return sectionDateFormatter.stringFromDate(createdAt)
        }
    }
}

