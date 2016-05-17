//
//  FayeClient.swift
//  Yep
//
//  Created by NIX on 16/5/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import SocketRocket

protocol FayeClientDelegate: class {

    func fayeClient(client: FayeClient, didConnectToURL URL: NSURL)
    func fayeClient(client: FayeClient, didDisconnectWithError error: NSError?)

    func fayeClient(client: FayeClient, didSubscribeToChannel channel: String)
    func fayeClient(client: FayeClient, didUnsubscribeFromChannel channel: String)

    func fayeClient(client: FayeClient, didFailWithError error: NSError?)
    func fayeClient(client: FayeClient, didFailDeserializeMessage message: [String: AnyObject])
    func fayeClient(client: FayeClient, didReceiveMessage messageInfo: [String: AnyObject], fromChannel channel: String)
}

class FayeClient {

    var webSocket: SRWebSocket?
    var serverURL: NSURL!
    var clientID: String!

    var sentMessageCount: Int = 0

    var subscriptionSet: Set<String> = []
    var pendingSubscriptionSet: Set<String> = []
    var openSubscriptionSet: Set<String> = []

    var extensions: [String: AnyObject] = [:]

    var shouldRetryConnection: Bool = true
    var retryInterval: NSTimeInterval = 1
    var retryAttempt: Int = 0
    let maximumRetryAttempts: Int = 5

    weak var delegate: FayeClientDelegate?

}

