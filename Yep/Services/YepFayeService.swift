//
//  YepFayeService.swift
//  Yep
//
//  Created by NIX on 16/5/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift
import YepKit
import YepNetworking
import FayeClient

protocol YepFayeServiceDelegate: class {

    func fayeRecievedInstantStateType(instantStateType: YepFayeService.InstantStateType, userID: String)

    /*
    func fayeRecievedNewMessages(AllMessageIDs: [String], messageAgeRawValue: MessageAge.RawValue)
    
    func fayeMessagesMarkAsReadByRecipient(lastReadAt: NSTimeInterval, recipientType: String, recipientID: String)
    */
}

private let fayeQueue = dispatch_queue_create("com.Yep.fayeQueue", DISPATCH_QUEUE_SERIAL)

final class YepFayeService: NSObject {

    static let sharedManager = YepFayeService()

    enum MessageType: String {
        case Default = "message"
        case Instant = "instant_state"
        case Read = "mark_as_read"
        case MessageDeleted = "message_deleted"
    }

    enum InstantStateType: Int, CustomStringConvertible {
        case Text = 0
        case Audio

        var description: String {
            switch self {
            case .Text:
                return NSLocalizedString("typing", comment: "")
            case .Audio:
                return NSLocalizedString("recording", comment: "")
            }
        }
    }

    let fayeClient: FayeClient = {
        let client = FayeClient(serverURL: fayeBaseURL)
        return client
    }()

    weak var delegate: YepFayeServiceDelegate?

    private lazy var realm: Realm = {
        return try! Realm()
    }()

    override init() {

        super.init()

        fayeClient.delegate = self
    }
}

// MARK: - Public

struct LastRead {

    let atUnixTime: NSTimeInterval
    let messageID: String
    let recipient: Recipient

    init?(info: JSONDictionary) {
        guard let atUnixTime = info["last_read_at"] as? NSTimeInterval else {
            println("LastRead: Missing key: last_read_at")
            return nil
        }
        guard let messageID = info["last_read_id"] as? String else {
            println("LastRead: Missing key: last_read_id")
            return nil
        }
        guard let recipientType = info["recipient_type"] as? String else {
            println("LastRead: Missing key: recipient_type")
            return nil
        }
        guard let recipientID = info["recipient_id"] as? String else {
            println("LastRead: Missing key: recipient_id")
            return nil
        }
        guard let conversationType = ConversationType(nameForServer: recipientType) else {
            println("LastRead: Create conversationType failed!")
            return nil
        }

        self.atUnixTime = atUnixTime
        self.messageID = messageID
        self.recipient = Recipient(type: conversationType, ID: recipientID)
    }
}

extension YepFayeService {

    func prepareForChannel(channel: String) {

        if let extensionData = extensionData() {
            fayeClient.setExtension(extensionData, forChannel: channel)
        }
    }

    func tryStartConnect() {

        dispatch_async(fayeQueue) { [weak self] in

            guard let strongSelf = self else { return }

            guard let userID = YepUserDefaults.userID.value, personalChannel = strongSelf.personalChannelWithUserID(userID) else {
                println("FayeClient startConnect failed, not userID or personalChannel!")
                return
            }

            println("Faye will subscribe \(personalChannel)")

            strongSelf.prepareForChannel("connect")
            strongSelf.prepareForChannel("handshake")
            strongSelf.prepareForChannel(personalChannel)

            strongSelf.fayeClient.connect()
        }
    }

    private func subscribeChannel() {

        dispatch_async(fayeQueue) { [weak self] in

            guard let userID = YepUserDefaults.userID.value, personalChannel = self?.personalChannelWithUserID(userID) else {
                println("FayeClient subscribeChannel failed, not userID or personalChannel!")
                return
            }

            self?.fayeClient.subscribeToChannel(personalChannel) { [weak self] data in

                println("receive faye data: \(data)")

                let info: JSONDictionary = data

                // Service 消息
                if let messageInfo = info["message"] as? JSONDictionary {

                    guard let realm = try? Realm() else {
                        return
                    }

                    realm.beginWrite()
                    let isServiceMessage = isServiceMessageAndHandleMessageInfo(messageInfo, inRealm: realm)
                    _ = try? realm.commitWrite()

                    if isServiceMessage {
                        return
                    }
                }

                guard let
                    messageTypeString = info["message_type"] as? String,
                    messageType = MessageType(rawValue: messageTypeString)
                    else {
                        println("Faye recieved unknown message type")
                        return
                }

                //println("messageType: \(messageType)")

                switch messageType {

                case .Default:

                    guard let messageInfo = info["message"] as? JSONDictionary else {
                        println("Error: Faye Default not messageInfo!")
                        break
                    }

                    self?.saveMessageWithMessageInfo(messageInfo)

                case .Instant:

                    guard let messageInfo = info["message"] as? JSONDictionary else {
                        println("Error: Faye Instant not messageInfo!")
                        break
                    }

                    if let
                        user = messageInfo["user"] as? JSONDictionary,
                        userID = user["id"] as? String,
                        state = messageInfo["state"] as? Int {

                        if let instantStateType = InstantStateType(rawValue: state) {
                            self?.delegate?.fayeRecievedInstantStateType(instantStateType, userID: userID)
                        }
                    }

                case .Read:

                    guard let messageInfo = info["message"] as? JSONDictionary else {
                        println("Error: Faye Read not messageInfo!")
                        break
                    }
                    guard let lastRead = LastRead(info: messageInfo) else {
                        break
                    }

                    SafeDispatch.async {
                        NSNotificationCenter.defaultCenter().postNotificationName(Config.Message.Notification.MessageBatchMarkAsRead, object: Box<LastRead>(lastRead))
                        //self?.delegate?.fayeMessagesMarkAsReadByRecipient(last_read_at, recipientType: recipient_type, recipientID: recipient_id)
                    }

                case .MessageDeleted:

                    guard let messageInfo = info["message"] as? JSONDictionary else {
                        println("Error: Faye MessageDeleted not messageInfo!")
                        break
                    }
                    guard let messageID = messageInfo["id"] as? String else {
                        break
                    }
                    
                    handleMessageDeletedFromServer(messageID: messageID)
                }
            }
        }
    }

    func sendInstantMessage(message: JSONDictionary, completion: (success: Bool) -> Void) {

        dispatch_async(fayeQueue) { [unowned self] in

            guard let extensionData = self.extensionData() else {
                println("Can NOT sendInstantMessage, not extensionData")
                completion(success: false)
                return
            }

            let data: JSONDictionary = [
                "api_version": "v1",
                "message_type": MessageType.Instant.rawValue,
                "message": message
            ]

            self.fayeClient.sendMessage(data, toChannel: self.instantChannel(), usingExtension: extensionData, usingBlock: { message  in

                if message.successful {
                    completion(success: true)

                } else {
                    completion(success: false)
                }
            })
        }
    }
}

// MARK: - Private

extension YepFayeService {

    private func extensionData() -> [String: String]? {

        if let v1AccessToken = YepUserDefaults.v1AccessToken.value {
            return [
                "access_token": v1AccessToken,
                "version": "v1",
            ]

        } else {
            return nil
        }
    }

    private func instantChannel() -> String {
        return "/messages"
    }

    private func personalChannelWithUserID(userID: String) -> String? {

        guard !userID.isEmpty else {
            return nil
        }

        return "/v1/users/\(userID)/messages"
    }

    private func saveMessageWithMessageInfo(messageInfo: JSONDictionary) {

        //println("faye received messageInfo: \(messageInfo)")

        func isMessageSendFromMe() -> Bool {

            guard let senderInfo = messageInfo["sender"] as? JSONDictionary, senderID = senderInfo["id"] as? String, currentUserID = YepUserDefaults.userID.value else {
                return false
            }

            return senderID == currentUserID
        }

        if isMessageSendFromMe() {

            // 如果收到的消息在本地的 SendingMessagesPool 里，那就不同步了
            if let tempMesssageID = messageInfo["random_id"] as? String {
                if SendingMessagesPool.containsMessage(with: tempMesssageID) {
                    println("SendingMessagesPool.containsMessage \(tempMesssageID)")
                    // 广播只有一次，可从池子里清除 tempMesssageID
                    SendingMessagesPool.removeMessage(with: tempMesssageID)
                    return
                }

            } else {
                // 是自己发的消息被广播过来，但没有 random_id，也不同步了
                println("isMessageSendFromMe but NOT random_id")
                return
            }
        }

        SafeDispatch.async {

            guard let realm = try? Realm() else {
                return
            }

            realm.beginWrite()

            var messageIDs: [String] = []

            syncMessageWithMessageInfo(messageInfo, messageAge: .New, inRealm: realm) { _messageIDs in

                messageIDs = _messageIDs
            }

            let _ = try? realm.commitWrite()

            tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
            /*
            self?.delegate?.fayeRecievedNewMessages(messageIDs, messageAgeRawValue: MessageAge.New.rawValue)
            // Notification 可能导致 Crash，Conversation 有可能在有些时候没有释放监听，但是现在还没找到没释放的原因
            // 上面的 Delegate fayeRecievedNewMessages 替代了 Notification
            */
        }
    }
}

// MARK: - FayeClientDelegate

extension YepFayeService: FayeClientDelegate {

    func fayeClient(client: FayeClient, didConnectToURL URL: NSURL) {

        println("fayeClient didConnectToURL \(URL)")

        subscribeChannel()
    }

    func fayeClient(client: FayeClient, didDisconnectWithError error: NSError?) {

        if let error = error {
            println("fayeClient didDisconnectWithError \(error.description)")
        }
    }

    func fayeClient(client: FayeClient, didSubscribeToChannel channel: String) {

        println("fayeClient didSubscribeToChannel \(channel)")
    }

    func fayeClient(client: FayeClient, didUnsubscribeFromChannel channel: String) {

        println("fayeClient didUnsubscribeFromChannel \(channel)")
    }

    func fayeClient(client: FayeClient, didFailWithError error: NSError?) {

        if let error = error {
            println("fayeClient didFailWithError \(error.description)")
        }
    }

    func fayeClient(client: FayeClient, didFailDeserializeMessage message: [String: AnyObject]?, withError error: NSError?) {

        if let error = error {
            println("fayeClient didFailDeserializeMessage \(error.description)")
        }
    }

    func fayeClient(client: FayeClient, didReceiveMessage messageData: [String: AnyObject], fromChannel channel: String) {

        println("fayeClient didReceiveMessage \(messageData)")
    }
}

