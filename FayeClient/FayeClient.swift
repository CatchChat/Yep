//
//  FayeClient.swift
//  Yep
//
//  Created by NIX on 16/5/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import SocketRocket
import Base64

public protocol FayeClientDelegate: class {

    func fayeClient(client: FayeClient, didConnectToURL URL: NSURL)
    func fayeClient(client: FayeClient, didDisconnectWithError error: NSError?)

    func fayeClient(client: FayeClient, didSubscribeToChannel channel: String)
    func fayeClient(client: FayeClient, didUnsubscribeFromChannel channel: String)

    func fayeClient(client: FayeClient, didFailWithError error: NSError?)
    func fayeClient(client: FayeClient, didFailDeserializeMessage message: [String: AnyObject]?, withError error: NSError?)
    func fayeClient(client: FayeClient, didReceiveMessage messageInfo: [String: AnyObject], fromChannel channel: String)
}

public typealias FayeClientSubscriptionHandler = (message: [String: AnyObject]) -> Void
public typealias FayeClientPrivateHandler = (message: FayeMessage) -> Void

public class FayeClient: NSObject {

    public private(set) var webSocket: SRWebSocket?
    public private(set) var serverURL: NSURL
    public private(set) var clientID: String?

    public private(set) var sentMessageCount: Int = 0

    private var pendingChannelSubscriptionSet: Set<String> = []
    private var openChannelSubscriptionSet: Set<String> = []
    private var subscribedChannels: [String: FayeClientSubscriptionHandler] = [:]
    private var privateChannels: [String: FayeClientPrivateHandler] = [:]
    private var channelExtensions: [String: AnyObject] = [:]

    public var shouldRetryConnection: Bool = true
    public var retryInterval: NSTimeInterval = 1
    public var retryAttempt: Int = 0
    public var maximumRetryAttempts: Int = 5
    private var reconnectTimer: NSTimer?

    public weak var delegate: FayeClientDelegate?

    private var connected: Bool = false
    public var isConnected: Bool {
        return connected
    }

    private var isWebSocketOpen: Bool {

        if let webSocket = webSocket {
            return webSocket.readyState == .OPEN
        }

        return false
    }

    private var isWebSocketClosed: Bool {

        if let webSocket = webSocket {
            return webSocket.readyState == .CLOSED
        }

        return true
    }

    deinit {
        subscribedChannels.removeAll()
        clearSubscriptions()

        invalidateReconnectTimer()
        disconnectFromWebSocket()
    }

    public init(serverURL: NSURL) {
        self.serverURL = serverURL

        super.init()
    }

    public class func clientWithURL(serverURL: NSURL) -> FayeClient {

        return FayeClient(serverURL: serverURL)
    }
}

// MARK: - Helpers

extension FayeClient {

    func generateUniqueMessageID() -> String {

        sentMessageCount += 1
        return ("\(sentMessageCount)" as NSString).base64String()
    }
}

// MARK: - Public methods

extension FayeClient {

    public func setExtension(extension: [String: AnyObject], forChannel channel: String) {

        channelExtensions[channel] = `extension`
    }

    public func removeExtensionForChannel(channel: String) {

        channelExtensions.removeValueForKey(channel)
    }

    public func sendMessage(message: [String: AnyObject], toChannel channel: String) {

        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: nil)
    }

    public func sendMessage(message: [String: AnyObject], toChannel channel: String, usingExtension extension: [String: AnyObject]?) {

        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: `extension`)
    }

    public func sendMessage(message: [String: AnyObject], toChannel channel: String, usingExtension extension: [String: AnyObject]?, usingBlock subscriptionHandler: FayeClientPrivateHandler) {

        let messageID = generateUniqueMessageID()

        privateChannels[messageID] = subscriptionHandler

        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: `extension`)
    }

    public func connectToURL(serverURL: NSURL) -> Bool {

        if isConnected || isWebSocketOpen {
            return false
        }

        self.serverURL = serverURL

        return connect()
    }

    public func connect() -> Bool {

        if isConnected || isWebSocketOpen {
            return false
        }

        connectToWebSocket()

        return true
    }

    public func disconnect() {

        sendBayeuxDisconnectMessage()
    }

    public func subscribeToChannel(channel: String) {

        subscribeToChannel(channel, usingBlock: nil)
    }

    public func subscribeToChannel(channel: String, usingBlock subscriptionHandler: FayeClientSubscriptionHandler?) {

        if let subscriptionHandler = subscriptionHandler {
            subscribedChannels[channel] = subscriptionHandler
        } else {
            subscribedChannels.removeValueForKey(channel)
        }

        if isConnected {
            sendBayeuxSubscribeMessageWithChannel(channel)
        }
    }

    public func unsubscribeFromChannel(channel: String) {

        subscribedChannels.removeValueForKey(channel)
        pendingChannelSubscriptionSet.remove(channel)

        if isConnected {
            sendBayeuxUnsubscribeMessageWithChannel(channel)
        }
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

private let FayeClientWebSocketErrorDomain = "com.nixWork.FayeClient.Error"

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

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient no clientID.")
            return
        }

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

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient no clientID.")
            return
        }

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelDisconnect,
            FayeClientBayeuxMessageClientIdKey: clientID,
        ]

        writeMessage(message)
    }

    func sendBayeuxSubscribeMessageWithChannel(channel: String) {

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient no clientID.")
            return
        }

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

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient no clientID.")
            return
        }

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelUnsubscribe,
            FayeClientBayeuxMessageClientIdKey: clientID,
            FayeClientBayeuxMessageSubscriptionKey: channel,
        ]

        writeMessage(message)
    }

    func sendBayeuxPublishMessage(messageInfo: [String: AnyObject], withMessageUniqueID messageID: String, toChannel channel: String, usingExtension extension: [String: AnyObject]?) {

        guard isConnected && isWebSocketOpen else {
            didFailWithMessage("FayeClient not connected to server.")
            return
        }

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient no clientID.")
            return
        }

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: channel,
            FayeClientBayeuxMessageClientIdKey: clientID,
            FayeClientBayeuxMessageDataKey: messageInfo,
            FayeClientBayeuxMessageIdKey: messageID,
        ]

        if let `extension` = `extension` {
            message[FayeClientBayeuxMessageExtensionKey] = `extension`

        } else {
            if let `extension` = channelExtensions[channel] {
                message[FayeClientBayeuxMessageExtensionKey] = `extension`
            }
        }

        writeMessage(message)
    }

    func clearSubscriptions() {

        pendingChannelSubscriptionSet.removeAll()
        openChannelSubscriptionSet.removeAll()
    }
}

// MARK: - Private methods

extension FayeClient {

    private func subscribePendingSubscriptions() {

        for channel in subscribedChannels.keys {

            if !pendingChannelSubscriptionSet.contains(channel) && !openChannelSubscriptionSet.contains(channel) {
                sendBayeuxSubscribeMessageWithChannel(channel)
            }
        }
    }

    @objc private func reconnectTimer(timer: NSTimer) {

        if isConnected {
            invalidateReconnectTimer()

        } else {

            if shouldRetryConnection && retryAttempt < maximumRetryAttempts {
                retryAttempt += 1

                connect()

            } else {
                invalidateReconnectTimer()
            }
        }
    }

    private func invalidateReconnectTimer() {

        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func reconnect() {

        guard shouldRetryConnection && retryAttempt < maximumRetryAttempts else {
            return
        }

        reconnectTimer = NSTimer.scheduledTimerWithTimeInterval(retryInterval, target: self, selector: #selector(FayeClient.reconnectTimer(_:)), userInfo: nil, repeats: false)
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

        } catch let error as NSError {
            delegate?.fayeClient(self, didFailDeserializeMessage: message, withError: error)

            completion?(finish: false)
        }
    }

    func connectToWebSocket() {

        disconnectFromWebSocket()

        let request = NSURLRequest(URL: serverURL)
        webSocket = SRWebSocket(URLRequest: request)
        webSocket?.delegate = self
        webSocket?.open()
    }

    func disconnectFromWebSocket() {

        webSocket?.delegate = nil
        webSocket?.close()
        webSocket = nil
    }

    func didFailWithMessage(message: String) {

        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: -100, userInfo: [NSLocalizedDescriptionKey: message])
        delegate?.fayeClient(self, didFailWithError: error)
    }

    func handleFayeMessages(messages: [[String: AnyObject]]) {

        //println("handleFayeMessages: \(messages)")
        let fayeMessages = messages.map({ FayeMessage.messageFromDictionary($0) }).flatMap({ $0 })

        fayeMessages.forEach({ fayeMessage in

            switch fayeMessage.channel {

            case FayeClientBayeuxChannelHandshake:

                if fayeMessage.successful {
                    retryAttempt = 0
                    clientID = fayeMessage.clientID
                    connected = true

                    delegate?.fayeClient(self, didConnectToURL: serverURL)

                    sendBayeuxConnectMessage()
                    subscribePendingSubscriptions()

                } else {
                    let message = String(format: "Faye client couldn't handshake with server. %@", fayeMessage.error ?? "")
                    didFailWithMessage(message)
                }

            case FayeClientBayeuxChannelConnect:

                if fayeMessage.successful {
                    connected = true
                    sendBayeuxConnectMessage()

                } else {
                    let message = String(format: "Faye client couldn't connect to server. %@", fayeMessage.error ?? "")
                    didFailWithMessage(message)
                }

            case FayeClientBayeuxChannelDisconnect:

                if fayeMessage.successful {
                    disconnectFromWebSocket()
                    connected = false
                    clearSubscriptions()

                    delegate?.fayeClient(self, didDisconnectWithError: nil)

                } else {
                    let message = String(format: "Faye client couldn't disconnect from server. %@", fayeMessage.error ?? "")
                    didFailWithMessage(message)
                }

            case FayeClientBayeuxChannelSubscribe:

                guard let subscription = fayeMessage.subscription else {
                    break
                }

                pendingChannelSubscriptionSet.remove(subscription)

                if fayeMessage.successful {
                    openChannelSubscriptionSet.insert(subscription)

                    delegate?.fayeClient(self, didSubscribeToChannel: subscription)

                } else {
                    let message = String(format: "Faye client couldn't subscribe channel %@ with server. %@", subscription, fayeMessage.error ?? "")
                    didFailWithMessage(message)
                }

            case FayeClientBayeuxChannelUnsubscribe:

                guard let subscription = fayeMessage.subscription else {
                    break
                }

                if fayeMessage.successful {
                    subscribedChannels.removeValueForKey(subscription)
                    pendingChannelSubscriptionSet.remove(subscription)
                    openChannelSubscriptionSet.remove(subscription)

                    delegate?.fayeClient(self, didUnsubscribeFromChannel: subscription)

                } else {
                    let message = String(format: "Faye client couldn't unsubscribe channel %@ with server. %@", subscription, fayeMessage.error ?? "")
                    didFailWithMessage(message)
                }

            default:

                if openChannelSubscriptionSet.contains(fayeMessage.channel) {

                    if let handler = subscribedChannels[fayeMessage.channel] {
                        handler(message: fayeMessage.data)

                    } else {
                        delegate?.fayeClient(self, didReceiveMessage: fayeMessage.data, fromChannel: fayeMessage.channel)
                    }

                } else {
                    // No match for channel
                    #if DEBUG
                    print("fayeMessage: \(fayeMessage)")
                    #endif

                    if let messageID = fayeMessage.ID, handler = privateChannels[messageID] {
                        handler(message: fayeMessage)
                    }
                }
            }
        })
    }
}

// MARK: - SRWebSocketDelegate

extension FayeClient: SRWebSocketDelegate {

    public func webSocketDidOpen(webSocket: SRWebSocket!) {

        sendBayeuxHandshakeMessage()
    }

    public func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {

        guard let message = message else {
            return
        }

        var _messageData: NSData?
        if let messageString = message as? String {
            _messageData = messageString.dataUsingEncoding(NSUTF8StringEncoding)
        } else {
            _messageData = message as? NSData
        }

        guard let messageData = _messageData else {
            return
        }

        do {
            if let messages = try NSJSONSerialization.JSONObjectWithData(messageData, options: []) as? [[String: AnyObject]] {
                handleFayeMessages(messages)
            }

        } catch let error as NSError {
            delegate?.fayeClient(self, didFailDeserializeMessage: nil, withError: error)
        }
    }

    public func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {

        connected = false

        clearSubscriptions()

        delegate?.fayeClient(self, didFailWithError: error)

        reconnect()
    }

    public func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {

        connected = false

        clearSubscriptions()

        let reason: String = reason ?? "Unknown Reason"
        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: reason])
        delegate?.fayeClient(self, didDisconnectWithError: error)

        reconnect()
    }
}

