//
//  NSDate+Yep.swift
//  Yep
//
//  Created by NIX on 15/4/13.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension NSDate {

    func firstDateInThisWeek() -> NSDate {
        var beginningOfWeek: NSDate?
        let calendar = NSCalendar.currentCalendar()
        calendar.rangeOfUnit(.WeekOfYear, startDate: &beginningOfWeek, interval: nil, forDate: self)
        return beginningOfWeek!
    }

    func isInCurrentWeek() -> Bool {
        let firstDateOfWeek = NSDate().firstDateInThisWeek()

        if self.compare(firstDateOfWeek) == .OrderedDescending {
            return true
        }

        return false
    }

    class func dateWithISO08601String(dateString: String?) -> NSDate {
        if let dateString = dateString {
            var dateString = dateString

            if dateString.hasSuffix("Z") {
                dateString = String(dateString.characters.dropLast()).stringByAppendingString("-0000")
            }

            return dateFromString(dateString, withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        }

        return NSDate()
    }

    class func dateFromString(dateString: String, withFormat dateFormat: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        if let date = dateFormatter.dateFromString(dateString) {
            return date
        } else {
            return NSDate()
        }
    }
}