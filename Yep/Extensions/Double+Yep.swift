//
//  Double+Yep.swift
//  Yep
//
//  Created by kevinzhow on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension Double {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }

    var yep_feedAudioTimeLengthString: String {
        let minutes = Int(self / 60)
        let seconds = Int(self % 60)
        return String(format: "%02d:%02d", minutes, seconds)
    }
}