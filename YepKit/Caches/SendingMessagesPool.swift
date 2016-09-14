//
//  SendingMessagesPool.swift
//  Yep
//
//  Created by NIX on 16/3/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

final public class SendingMessagesPool {

    private static var sharedPool = SendingMessagesPool()

    private init() {
    }

    private var messageIDSet = Set<String>()

    public class func containsMessage(with messsageID: String) -> Bool {

        return sharedPool.messageIDSet.contains(messsageID)
    }

    public class func addMessage(with messsageID: String) {

        sharedPool.messageIDSet.insert(messsageID)
    }

    public class func removeMessage(with messsageID: String) {

        sharedPool.messageIDSet.remove(messsageID)
    }
}

