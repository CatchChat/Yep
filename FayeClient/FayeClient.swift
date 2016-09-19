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

    func fayeClient(_ client: FayeClient, didConnectToURL URL: URL)
    func fayeClient(_ client: FayeClient, didDisconnectWithError error: Error?)

    func fayeClient(_ client: FayeClient, didSubscribeToChannel channel: String)
    func fayeClient(_ client: FayeClient, didUnsubscribeFromChannel channel: String)

    func fayeClient(_ client: FayeClient, didFailWithError error: Error?)
    func fayeClient(_ client: FayeClient, didFailDeserializeMessage message: [String: AnyObject]?, withError error: Error?)
    func fayeClient(_ client: FayeClient, didReceiveMessage messageInfo: [String: AnyObject], fromChannel channel: String)
}

public typealias FayeClientSubscriptionHandler = (_ message: [String: AnyObject]) -> Void
public typealias FayeClientPrivateHandler = (_ message: FayeMessage) -> Void

open class FayeClient: NSObject {

    open fileprivate(set) var webSocket: SRWebSocket?
    open fileprivate(set) var serverURL: URL
    open fileprivate(set) var clientID: String?

    open fileprivate(set) var sentMessageCount: Int = 0

    fileprivate var pendingChannelSubscriptionSet: Set<String> = []
    fileprivate var openChannelSubscriptionSet: Set<String> = []
    fileprivate var subscribedChannels: [String: FayeClientSubscriptionHandler] = [:]
    fileprivate var privateChannels: [String: FayeClientPrivateHandler] = [:]
    fileprivate var channelExtensions: [String: AnyObject] = [:]

    open var shouldRetryConnection: Bool = true
    open var retryInterval: TimeInterval = 1
    open var retryAttempt: Int = 0
    open var maximumRetryAttempts: Int = 5
    fileprivate var reconnectTimer: Timer?

    open weak var delegate: FayeClientDelegate?

    fileprivate var connected: Bool = false
    open var isConnected: Bool {
        return connected
    }

    fileprivate var isWebSocketOpen: Bool {

        if let webSocket = webSocket {
            return webSocket.readyState == .OPEN
        }

        return false
    }

    fileprivate var isWebSocketClosed: Bool {

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

    public init(serverURL: URL) {
        self.serverURL = serverURL

        super.init()
    }

    open class func clientWithURL(_ serverURL: URL) -> FayeClient {

        return FayeClient(serverURL: serverURL)
    }
}

// MARK: - Helpers

extension FayeClient {

    func generateUniqueMessageID() -> String {

        sentMessageCount += 1
        return ("\(sentMessageCount)" as NSString).base64()
    }
}

// MARK: - Public methods

extension FayeClient {

    public func setExtension(_ _extension: [String: AnyObject], forChannel channel: String) {

        channelExtensions[channel] = _extension as AnyObject?
    }

    public func removeExtensionForChannel(_ channel: String) {

        channelExtensions.removeValue(forKey: channel)
    }

    public func sendMessage(_ message: [String: AnyObject], toChannel channel: String) {

        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: nil)
    }

    public func sendMessage(_ message: [String: AnyObject], toChannel channel: String, usingExtension _extension: [String: AnyObject]?) {

        let messageID = generateUniqueMessageID()
        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: _extension)
    }

    public func sendMessage(_ message: [String: AnyObject], toChannel channel: String, usingExtension _extension: [String: AnyObject]?, usingBlock subscriptionHandler: @escaping FayeClientPrivateHandler) {

        let messageID = generateUniqueMessageID()

        privateChannels[messageID] = subscriptionHandler

        sendBayeuxPublishMessage(message, withMessageUniqueID: messageID, toChannel: channel, usingExtension: _extension)
    }

    public func connectToURL(_ serverURL: URL) -> Bool {

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

    public func subscribeToChannel(_ channel: String) {

        subscribeToChannel(channel, usingBlock: nil)
    }

    public func subscribeToChannel(_ channel: String, usingBlock subscriptionHandler: FayeClientSubscriptionHandler?) {

        if let subscriptionHandler = subscriptionHandler {
            subscribedChannels[channel] = subscriptionHandler
        } else {
            subscribedChannels.removeValue(forKey: channel)
        }

        if isConnected {
            sendBayeuxSubscribeMessageWithChannel(channel)
        }
    }

    public func unsubscribeFromChannel(_ channel: String) {

        subscribedChannels.removeValue(forKey: channel)
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
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelHandshake as AnyObject,
            FayeClientBayeuxMessageVersionKey: FayeClientBayeuxVersion as AnyObject,
            FayeClientBayeuxMessageMinimuVersionKey: FayeClientBayeuxMinimumVersion as AnyObject,
            FayeClientBayeuxMessageSupportedConnectionTypesKey: supportedConnectionTypes as AnyObject,
        ]

        if let _extension = channelExtensions["handshake"] {
            message[FayeClientBayeuxMessageExtensionKey] = _extension
        }

        writeMessage(message)
    }

    func sendBayeuxConnectMessage() {

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient has not clientID!")
            return
        }

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelConnect as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageConnectionTypeKey: FayeClientBayeuxConnectionTypeWebSocket as AnyObject,
        ]

        if let _extension = channelExtensions["connect"] {
            message[FayeClientBayeuxMessageExtensionKey] = _extension
        }

        writeMessage(message)
    }

    func sendBayeuxDisconnectMessage() {

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient has not clientID!")
            return
        }

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelDisconnect as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
        ]

        writeMessage(message)
    }

    func sendBayeuxSubscribeMessageWithChannel(_ channel: String) {

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient has not clientID!")
            return
        }

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelSubscribe as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageSubscriptionKey: channel as AnyObject,
        ]

        if let _extension = channelExtensions[channel] {
            message[FayeClientBayeuxMessageExtensionKey] = _extension
        }

        writeMessage(message) { [weak self] finish in
            if finish {
                self?.pendingChannelSubscriptionSet.insert(channel)
            }
        }
    }

    func sendBayeuxUnsubscribeMessageWithChannel(_ channel: String) {

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient has not clientID!")
            return
        }

        let message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: FayeClientBayeuxChannelUnsubscribe as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageSubscriptionKey: channel as AnyObject,
        ]

        writeMessage(message)
    }

    func sendBayeuxPublishMessage(_ messageInfo: [String: AnyObject], withMessageUniqueID messageID: String, toChannel channel: String, usingExtension _extension: [String: AnyObject]?) {

        guard isConnected && isWebSocketOpen else {
            didFailWithMessage("FayeClient not connected to server.")
            return
        }

        guard let clientID = clientID else {
            didFailWithMessage("FayeClient has not clientID!")
            return
        }

        var message: [String: AnyObject] = [
            FayeClientBayeuxMessageChannelKey: channel as AnyObject,
            FayeClientBayeuxMessageClientIdKey: clientID as AnyObject,
            FayeClientBayeuxMessageDataKey: messageInfo as AnyObject,
            FayeClientBayeuxMessageIdKey: messageID as AnyObject,
        ]

        if let _extension = _extension {
            message[FayeClientBayeuxMessageExtensionKey] = _extension as AnyObject?

        } else {
            if let _extension = channelExtensions[channel] {
                message[FayeClientBayeuxMessageExtensionKey] = _extension
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

    fileprivate func subscribePendingSubscriptions() {

        func canPending(_ channel: String) -> Bool {
            return !pendingChannelSubscriptionSet.contains(channel)
                && !openChannelSubscriptionSet.contains(channel)
        }

        subscribedChannels.keys.filter({ canPending($0) }).forEach({
            sendBayeuxSubscribeMessageWithChannel($0)
        })
    }

    @objc fileprivate func reconnectTimer(_ timer: Timer) {

        if isConnected {
            invalidateReconnectTimer()

        } else {
            if shouldRetryConnection && retryAttempt < maximumRetryAttempts {
                retryAttempt += 1

                _ = connect()

            } else {
                invalidateReconnectTimer()
            }
        }
    }

    fileprivate func invalidateReconnectTimer() {

        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    fileprivate func reconnect() {

        guard shouldRetryConnection && retryAttempt < maximumRetryAttempts else {
            return
        }

        reconnectTimer = Timer.scheduledTimer(timeInterval: retryInterval, target: self, selector: #selector(FayeClient.reconnectTimer(_:)), userInfo: nil, repeats: false)
    }
}

// MARK: - SRWebSocket

extension FayeClient {

    func writeMessage(_ message: [String: AnyObject], completion: ((_ finish: Bool) -> Void)? = nil) {

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            webSocket?.send(jsonString)

            completion?(true)

        } catch let error as NSError {
            delegate?.fayeClient(self, didFailDeserializeMessage: message, withError: error)

            completion?(false)
        }
    }

    func connectToWebSocket() {

        disconnectFromWebSocket()

        let request = URLRequest(url: serverURL)
        webSocket = SRWebSocket(urlRequest: request)
        webSocket?.delegate = self
        webSocket?.open()
    }

    func disconnectFromWebSocket() {

        webSocket?.delegate = nil
        webSocket?.close()
        webSocket = nil
    }

    func didFailWithMessage(_ message: String) {

        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: -100, userInfo: [NSLocalizedDescriptionKey: message])
        delegate?.fayeClient(self, didFailWithError: error)
    }

    func handleFayeMessages(_ messages: [[String: AnyObject]]) {

        //print("handleFayeMessages: \(messages)")
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
                    subscribedChannels.removeValue(forKey: subscription)
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
                        handler(fayeMessage.data)

                    } else {
                        delegate?.fayeClient(self, didReceiveMessage: fayeMessage.data, fromChannel: fayeMessage.channel)
                    }

                } else {
                    // No match for channel
                    #if DEBUG
                    print("fayeMessage: \(fayeMessage)")
                    #endif

                    if let messageID = fayeMessage.ID, let handler = privateChannels[messageID] {
                        handler(fayeMessage)
                    }
                }
            }
        })
    }
}

// MARK: - SRWebSocketDelegate

extension FayeClient: SRWebSocketDelegate {

    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {

        sendBayeuxHandshakeMessage()
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {

        guard let message = message else {
            return
        }

        var _messageData: Data?
        if let messageString = message as? String {
            _messageData = messageString.data(using: String.Encoding.utf8)
        } else {
            _messageData = message as? Data
        }

        guard let messageData = _messageData else {
            return
        }

        do {
            if let messages = try JSONSerialization.jsonObject(with: messageData, options: []) as? [[String: AnyObject]] {
                handleFayeMessages(messages)
            }

        } catch let error as NSError {
            delegate?.fayeClient(self, didFailDeserializeMessage: nil, withError: error)
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {

        connected = false

        clearSubscriptions()

        delegate?.fayeClient(self, didFailWithError: error)

        reconnect()
    }

    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {

        connected = false

        clearSubscriptions()

        let reason: String = reason ?? "Unknown Reason"
        let error = NSError(domain: FayeClientWebSocketErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: reason])
        delegate?.fayeClient(self, didDisconnectWithError: error)

        reconnect()
    }
}

