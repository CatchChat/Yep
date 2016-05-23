//
//  SendingMessagePool.swift
//  Yep
//
//  Created by NIX on 16/3/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final public class SendingMessagePool {

    private static var sharedPool = SendingMessagePool()

    private init() {
    }

    var tempMessageIDSet = Set<String>()

    public class func containsMessage(tempMesssageID tempMesssageID: String) -> Bool {

        return sharedPool.tempMessageIDSet.contains(tempMesssageID)
    }

    public class func addMessage(tempMesssageID tempMesssageID: String) {

        sharedPool.tempMessageIDSet.insert(tempMesssageID)
    }

    public class func removeMessage(tempMesssageID tempMesssageID: String) {

        sharedPool.tempMessageIDSet.remove(tempMesssageID)
    }
}
