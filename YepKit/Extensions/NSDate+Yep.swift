//
//  NSDate+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public extension NSDate {

    public class func dateWithISO08601String(dateString: String?) -> NSDate {
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

