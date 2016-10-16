//
//  Date+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public extension Date {

    public static func dateWithISO08601String(_ dateString: String?) -> Date {
        if let dateString = dateString {
            var dateString = dateString

            if dateString.hasSuffix("Z") {
                dateString = String(dateString.characters.dropLast()) + "-0000"
            }

            return dateFromString(dateString, withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        }
        
        return Date()
    }

    static func dateFromString(_ dateString: String, withFormat dateFormat: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            return Date()
        }
    }
}

