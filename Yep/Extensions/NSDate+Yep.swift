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
}

