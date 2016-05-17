//
//  FayeClient.swift
//  Yep
//
//  Created by NIX on 16/5/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import SocketRocket

public protocol FayeClientDelegate: class {

    func fayeClient(client: FayeClient, didConnectToURL URL: NSURL)
    func fayeClient(client: FayeClient, didDisconnectWithError error: NSError?)

    func fayeClient(client: FayeClient, didSubscribeToChannel channel: String)
    func fayeClient(client: FayeClient, didUnsubscribeFromChannel channel: String)

    func fayeClient(client: FayeClient, didFailWithError error: NSError?)
    func fayeClient(client: FayeClient, didFailDeserializeMessage message: [String: AnyObject])
    func fayeClient(client: FayeClient, didReceiveMessage messageInfo: [String: AnyObject], fromChannel channel: String)
}

public class FayeClient {

    public private(set) var webSocket: SRWebSocket?
    public private(set)var serverURL: NSURL!
    public private(set) var clientID: String!

    public private(set) var sentMessageCount: Int = 0

    public private(set) var subscriptionSet: Set<String> = []
    public private(set) var pendingSubscriptionSet: Set<String> = []
    public private(set) var openSubscriptionSet: Set<String> = []

    private var subscribedChannels: [String: AnyObject] = [:]
    private var privateChannels: [String: AnyObject] = [:]
    private var channelExtensions: [String: AnyObject] = [:]

    public private(set) var extensions: [String: AnyObject] = [:]

    public var shouldRetryConnection: Bool = true
    public var retryInterval: NSTimeInterval = 1
    public var retryAttempt: Int = 0
    public var maximumRetryAttempts: Int = 5
    private var reconnectTimer: NSTimer?

    public weak var delegate: FayeClientDelegate?

    private var connected: Bool = false
    private var isConnected: Bool {
        return connected
    }

    private var webSocketOpen: Bool = false
    private var isWebSocketOpen: Bool {
        return webSocketOpen
    }

    private var webSocketClosed: Bool = false
    private var isWebSocketClosed: Bool {
        return webSocketClosed
    }

    public init() {

    }

    public convenience init(serverURL: NSURL) {
        self.init()

        self.serverURL = serverURL
    }

    public class func client() -> FayeClient {

        return FayeClient()
    }

    public class func clientWithURL(serverURL: NSURL) -> FayeClient {

        return FayeClient(serverURL: serverURL)
    }

}

