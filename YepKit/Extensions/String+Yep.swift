//
//  String+Yep.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

public extension String {

    public func contains(find: String) -> Bool{
        return self.rangeOfString(find) != nil
    }
}


public extension String {

    public func yep_mentionedMeInRealm(realm: Realm) -> Bool {

        guard let me = meInRealm(realm) else {
            return false
        }

        let username = me.username

        if !username.isEmpty {
            if self.containsString("@\(username)") {
                return true
            }
        }
        
        return false
    }
}

public extension String {

    public func yep_appendArrow() -> String {
        return self + " ▾"
    }
}

