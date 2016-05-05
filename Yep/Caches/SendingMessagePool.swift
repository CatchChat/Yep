//
//  SendingMessagePool.swift
//  Yep
//
//  Created by NIX on 16/3/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final class SendingMessagePool {

    private static var sharedPool = SendingMessagePool()

    private init() {
    }

    var tempMessageIDSet = Set<String>()

    class func containsMessage(tempMesssageID tempMesssageID: String) -> Bool {

        return sharedPool.tempMessageIDSet.contains(tempMesssageID)
    }

    class func addMessage(tempMesssageID tempMesssageID: String) {

        sharedPool.tempMessageIDSet.insert(tempMesssageID)
    }

    class func removeMessage(tempMesssageID tempMesssageID: String) {

        sharedPool.tempMessageIDSet.remove(tempMesssageID)
    }
}
