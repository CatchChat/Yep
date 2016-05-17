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

    private var pendingChannelSubscriptionSet: Set<String> = []
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

private let FayeClientBayeuxConnectionTypeLongPolling = "long-polling"
private let FayeClientBayeuxConnectionTypeCallbackPolling = "callback-polling"
private let FayeClientBayeuxConnectionTypeIFrame = "iframe";
private let FayeClientBayeuxConnectionTypeWebSocket = "websocket"

private let FayeClientBayeuxChannelHandshake = "/meta/handshake"
private let FayeClientBayeuxChannelConnect = "/meta/connect"
private let FayeClientBayeuxChannelDisconnect = "/meta/disconnect"
private let FayeClientBayeuxChannelSubscribe = "/meta/subscribe"
private let FayeClientBayeuxChannelUnsubscribe = "/meta/unsubscribe"

private let FayeClientBayeuxVersion = "1.0"
private let FayeClientBayeuxMinimumVersion = "1.0beta"

private let FayeClientBayeuxMessageChannelKey = "channel"
private let FayeClientBayeuxMessageClientIdKey = "clientId"
private let FayeClientBayeuxMessageIdKey = "id"
private let FayeClientBayeuxMessageDataKey = "data"
private let FayeClientBayeuxMessageSubscriptionKey = "subscription"
private let FayeClientBayeuxMessageExtensionKey = "ext"
private let FayeClientBayeuxMessageVersionKey = "version"
private let FayeClientBayeuxMessageMinimuVersionKey = "minimumVersion"
private let FayeClientBayeuxMessageSupportedConnectionTypesKey = "supportedConnectionTypes"
private let FayeClientBayeuxMessageConnectionTypeKey = "connectionType"

// MARK: - Bayeux procotol messages

extension FayeClient {

    func sendBayeuxHandshakeMessage() {

        let supportedConnectionTypes: [String] = [
            FayeClientBayeuxConnectionTypeLongPolling,
            FayeClientBayeuxConnectionTypeCallbackPolling,
            FayeClientBayeuxConnectionTypeIFrame,
            FayeClientBayeuxConnectionTypeWebSocket,
        ]

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelHandshake,
            FayeClientBayeuxMessageVersionKey: FayeClientBayeuxVersion,
            FayeClientBayeuxMessageMinimuVersionKey: FayeClientBayeuxMinimumVersion,
            FayeClientBayeuxMessageSupportedConnectionTypesKey: supportedConnectionTypes,
        ]

        if let `extension` = channelExtensions["handshake"] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }

        writeMessage(message)
    }

    func sendBayeuxConnectMessage() {

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelConnect,
            FayeClientBayeuxMessageClientIdKey: clientID,
            FayeClientBayeuxMessageConnectionTypeKey: FayeClientBayeuxConnectionTypeWebSocket,
        ]

        if let `extension` = channelExtensions["connect"] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }

        writeMessage(message)
    }

    func sendBayeuxDisconnectMessage() {

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelDisconnect,
            FayeClientBayeuxMessageClientIdKey: clientID,
        ]

        writeMessage(message)
    }

    func sendBayeuxSubscribeMessageWithChannel(channel: String) {

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelSubscribe,
            FayeClientBayeuxMessageClientIdKey: clientID,
            FayeClientBayeuxMessageSubscriptionKey: channel,
        ]

        if let `extension` = channelExtensions[channel] {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`
        }

        writeMessage(message) { [weak self] finish in

            if finish {
                self?.pendingChannelSubscriptionSet.insert(channel)
            }
        }
    }

    func sendBayeuxUnsubscribeMessageWithChannel(channel: String) {

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelUnsubscribe,
            FayeClientBayeuxMessageClientIdKey: clientID,
            FayeClientBayeuxMessageSubscriptionKey: channel,
        ]

        writeMessage(message)
    }
}

// MARK: - SRWebSocket

extension FayeClient {

    func writeMessage(message: [String: AnyObject], completion: ((finish: Bool) -> Void)? = nil) {

        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(message, options: NSJSONWritingOptions(rawValue: 0))

            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            webSocket?.send(jsonString)

            completion?(finish: true)

        } catch _ {
            delegate?.fayeClient(self, didFailDeserializeMessage: message)

            completion?(finish: false)
        }
    }
}

