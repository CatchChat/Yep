//
//  Date+Yep.swift
//  Yep
//
//  Created by NIX on 15/4/13.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension Date {

    var yep_isInWeekend: Bool {
        return Calendar.current.isDateInWeekend(self)
    }
}

