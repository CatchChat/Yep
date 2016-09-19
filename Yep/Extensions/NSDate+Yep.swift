//
//  NSDate+Yep.swift
//  Yep
//
//  Created by NIX on 15/4/13.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension Date {

    func firstDateInThisWeek() -> Date {
        var beginningOfWeek: Date?
        let calendar = Calendar.current
        (calendar as NSCalendar).range(of: .weekOfYear, start: &beginningOfWeek, interval: nil, for: self)
        return beginningOfWeek!
    }

    func isInCurrentWeek() -> Bool {
        let firstDateOfWeek = Date().firstDateInThisWeek()

        if self.compare(firstDateOfWeek) == .orderedDescending {
            return true
        }

        return false
    }
}

