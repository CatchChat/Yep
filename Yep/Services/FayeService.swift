//
//  YepMessageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol FayeServiceDelegate: class {
    /**
    * Current Typing Status
    *
    */
    func fayeRecievedInstantStateType(instantStateType: FayeService.InstantStateType, userID: String)

    /*
    func fayeRecievedNewMessages(AllMessageIDs: [String], messageAgeRawValue: MessageAge.RawValue)
    
    func fayeMessagesMarkAsReadByRecipient(lastReadAt: NSTimeInterval, recipientType: String, recipientID: String)
    */
}

let fayeQueue = dispatch_queue_create("com.Yep.fayeQueue", DISPATCH_QUEUE_SERIAL)

class FayeService: NSObject, MZFayeClientDelegate {

    static let sharedManager = FayeService()

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

    let client: MZFayeClient = {
        let client = MZFayeClient(URL:fayeBaseURL)
        return client
    }()

    weak var delegate: FayeServiceDelegate?
    
    override init() {
        
        super.init()
        
        client.delegate = self
    }

    // MARK: Public
    
    func prepareForChannel(channel: String) {
        if let extensionData = extensionData() {
            client.setExtension(extensionData, forChannel: channel)
        }
    }
    
    func unsubscribeGroup(groupID groupID: String) {
        let circleChannel = circleChannelWithCircleID(groupID)
        
        prepareForChannel(circleChannel!)
        
        client.unsubscribeFromChannel(circleChannel)
    }
    
    func subscribeGroup(groupID groupID: String) {
        dispatch_async(fayeQueue) { [weak self] in

            let circleChannel = self?.circleChannelWithCircleID(groupID)
            
            self?.prepareForChannel(circleChannel!)
            
            self?.client.subscribeToChannel(circleChannel, usingBlock: { data in
                //println("subscribeToChannel: \(data)")
                if let
                    messageInfo = data as? JSONDictionary,
                    messageType = messageInfo["message_type"] as? String {
                        
                        switch messageType {
                            
                        case FayeService.MessageType.Default.rawValue:
                            if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                                self?.saveMessageWithMessageInfo(messageDataInfo)
                            }
                            
                        case FayeService.MessageType.Instant.rawValue:
                            if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                                
                                if let
                                    user = messageDataInfo["user"] as? JSONDictionary,
                                    userID = user["id"] as? String,
                                    state = messageDataInfo["state"] as? Int {
                                        
                                        if let instantStateType = InstantStateType(rawValue: state) {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                self?.delegate?.fayeRecievedInstantStateType(instantStateType, userID: userID)
                                            }
                                        }
                                }
                            }
                            
                        case FayeService.MessageType.Read.rawValue:
                            break
                        default:
                            println("Recieved unknow message type")
                        }
                }
            })
        }
    }

    func startConnect() {
        if
            let userID = YepUserDefaults.userID.value {
                
                let personalChannel = personalChannelWithUserID(userID)

                println("Will Subscribe \(personalChannel)")
                
                prepareForChannel("connect")
                
                prepareForChannel("handshake")
                
                prepareForChannel(personalChannel!)
                
                dispatch_async(fayeQueue) { [weak self] in

                    self?.client.subscribeToChannel(personalChannel, usingBlock: { data in
                        //println("subscribeToChannel: \(data)")
                        guard let
                            messageInfo = data as? JSONDictionary,
                            messageTypeString = messageInfo["message_type"] as? String,
                            messageType = FayeService.MessageType(rawValue: messageTypeString)
                        else {
                            println("Faye recieved unknown message type")
                            return
                        }

                        //println("messageType: \(messageType)")

                        switch messageType {

                        case .Default:

                            if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                                self?.saveMessageWithMessageInfo(messageDataInfo)
                            }

                        case .Instant:

                            if let messageDataInfo = messageInfo["message"] as? JSONDictionary {

                                if let
                                    user = messageDataInfo["user"] as? JSONDictionary,
                                    userID = user["id"] as? String,
                                    state = messageDataInfo["state"] as? Int {

                                        if let instantStateType = InstantStateType(rawValue: state) {
                                            self?.delegate?.fayeRecievedInstantStateType(instantStateType, userID: userID)
                                        }
                                }
                            }
                            
                        case .Read:

                            if let messageDataInfo = messageInfo["message"] as? JSONDictionary {

                                //println("Faye Read: \(messageDataInfo)")
                                
                                if let
                                    lastReadAt = messageDataInfo["last_read_at"] as? NSTimeInterval,
                                    lastReadMessageID = messageDataInfo["last_read_id"] as? String,
                                    recipientType = messageDataInfo["recipient_type"] as? String,
                                    recipientID = messageDataInfo["recipient_id"] as? String {
                                        
                                        dispatch_async(dispatch_get_main_queue()) {
                                            NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageBatchMarkAsRead, object: ["last_read_at": lastReadAt, "last_read_id": lastReadMessageID, "recipient_type": recipientType, "recipient_id": recipientID])
                                           //self?.delegate?.fayeMessagesMarkAsReadByRecipient(last_read_at, recipientType: recipient_type, recipientID: recipient_id)
                                        }
                                }
                            }

                        case .MessageDeleted:

                            guard let
                                messageInfo = messageInfo["message"] as? JSONDictionary,
                                messageID = messageInfo["id"] as? String
                            else {
                                break
                            }

                            handleMessageDeletedFromServer(messageID: messageID)
                        }
                    })

                    self?.client.connect()
                }

        } else {
            println("FayeClient start failed!!!!")
        }
    }

    // MARK: Private
    
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

    private func personalChannelWithUserID(userID: String) -> String?{
        return "/v1/users/\(userID)/messages"
    }
    
    private func circleChannelWithCircleID(circleID: String) -> String?{
        return "/v1/circles/\(circleID)/messages"
    }

    private lazy var realm: Realm = {
        return try! Realm()
    }()

    private func saveMessageWithMessageInfo(messageInfo: JSONDictionary) {

        //println("faye received messageInfo: \(messageInfo)")

        func isMessageSendFromMe() -> Bool {

            guard let senderInfo = messageInfo["sender"] as? JSONDictionary, senderID = senderInfo["id"] as? String, currentUserID = YepUserDefaults.userID.value else {
                return false
            }

            return senderID == currentUserID
        }

        if isMessageSendFromMe() {
            return
        }
        /*
        // 如果消息来自自己，而且本地已有（可见是原始发送者），那就不用同步了

        if isMessageSendFromMe() {
            if let messageID = messageInfo["id"] as? String, _ = messageWithMessageID(messageID, inRealm: realm) {
                return
            }
        }
        */

        dispatch_async(realmQueue) {
            
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

    // MARK: MZFayeClientDelegate
    
    func fayeClient(client: MZFayeClient!, didConnectToURL url: NSURL!) {
        println("fayeClient didConnectToURL \(url)")
    }
    
    func fayeClient(client: MZFayeClient!, didDisconnectWithError error: NSError?) {
        
        if let error = error {
            println("fayeClient didDisconnectWithError \(error.description)")
        }
    }
    
    func fayeClient(client: MZFayeClient!, didFailDeserializeMessage message: [NSObject : AnyObject]!, withError error: NSError!) {
        println("fayeClient didFailDeserializeMessage \(error.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didFailWithError error: NSError!) {
        println("fayeClient didFailWithError \(error.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didReceiveMessage messageData: [NSObject : AnyObject]!, fromChannel channel: String!) {
        println("fayeClient didReceiveMessage \(messageData)")
    }
    
    func fayeClient(client: MZFayeClient!, didSubscribeToChannel channel: String!) {
        println("fayeClient didSubscribeToChannel \(channel)")
    }
    
    func fayeClient(client: MZFayeClient!, didUnsubscribeFromChannel channel: String!) {
        println("fayeClient didUnsubscribeFromChannel \(channel)")
    }
    
    func sendPrivateMessage(message: JSONDictionary, messageType: FayeService.MessageType, userID: String, completion: (success: Bool, messageID: String?) -> Void) {
        dispatch_async(fayeQueue) { [unowned self] in

            if let
                userChannel = self.personalChannelWithUserID(userID),
                extensionData = self.extensionData() {

                    let data: JSONDictionary = [
                        "api_version": "v1",
                        "message_type": messageType.rawValue,
                        "message": message
                    ]

                    self.client.sendMessage(data, toChannel: userChannel, usingExtension: extensionData, usingBlock: { message  in
                        if messageType == .Default {
                            println("sendPrivateMessage-Default \(message.successful)")

                        } else if messageType == .Instant {
                            println("sendPrivateMessage-Instant \(message.successful)")

                        } else {
                            println("sendPrivateMessage-\(messageType) \(message.successful)")
                        }

                        if message.successful == 1 {
                            if let
                                messageData = message.ext["message"] as? JSONDictionary,
                                messageID = messageData["id"] as? String {

                                    completion(success: true, messageID: messageID)

                            } else {
                                completion(success: true, messageID: nil)
                            }

                        } else {
                            completion(success: false, messageID: nil)
                        }
                    })

            } else {
                println("Can NOT sendPrivateMessage, not circleChannel or extensionData")

                completion(success: false, messageID: nil)
            }
        }
    }
    
    func sendGroupMessage(message: JSONDictionary, circleID: String, completion: (success: Bool, messageID: String?) -> Void)  {
        
        if let
            circleChannel = circleChannelWithCircleID(circleID),
            extensionData = extensionData() {
                
                let data: JSONDictionary = [
                    "api_version": "v1",
                    "message_type": FayeService.MessageType.Default.rawValue,
                    "message": message
                ]
                
                client.sendMessage(data, toChannel: circleChannel, usingExtension: extensionData, usingBlock: { message  in
                    println("sendGroupMessage \(message.successful)")

                    if message.successful == 1 {
                        if let
                            messageData = message.ext["message"] as? [String: String],
                            messageID = messageData["id"] {

                                completion(success: true, messageID: messageID)

                                return
                        }
                    }

                    completion(success: false, messageID: nil)
                })

        } else {
            println("Can NOT sendGroupMessage, not circleChannel or extensionData")

            completion(success: false, messageID: nil)
        }
    }

}
