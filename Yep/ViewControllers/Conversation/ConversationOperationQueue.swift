//
//  ConversationOperationQueue.swift
//  Yep
//
//  Created by kevinzhow on 15/5/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit


enum MessageStateOperationType: Int {
    case Sent
    case Read
}

struct MessageStateOperation {
    var type: MessageStateOperationType
    var messageID: String
}

class ConversationOperationQueue: NSObject {

    static let sharedManager = ConversationOperationQueue()

    var oprationQueue = [MessageStateOperation]()
    
    var lock = false
    
    func addNewQperationQueue(opration: MessageStateOperation) {
        
        println(opration)
        
        oprationQueue.append(opration)
        
        NSNotificationCenter.defaultCenter().postNotificationName("", object: nil)
    }
}
