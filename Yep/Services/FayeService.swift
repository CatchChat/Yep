//
//  YepMessageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MZFayeClient
import RealmSwift

protocol FayeServiceDelegate: class {
    /**
    * Current Typing Status
    *
    */
    func fayeRecievedInstantStateType(instantStateType: FayeService.InstantStateType, userID: String)
}

class FayeService: NSObject, MZFayeClientDelegate {

    static let sharedManager = FayeService()

    enum MessageType: String {
        case Default = "message"
        case Instant = "instant_state"
        case Read = "mark_as_read"
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

    let client: MZFayeClient

    weak var delegate: FayeServiceDelegate?
    
    override init() {

        client = MZFayeClient(URL:fayeBaseURL)
        
        super.init()
        
        client.delegate = self
    }

    // MARK: Public
    
    func prepareForChannel(channel: String) {
        if let extensionData = extensionData() {
            client.setExtension(extensionData, forChannel: channel)
        }
    }
    
    func subscribeGroup(groupID groupID: String) {
        
        let circleChannel = circleChannelWithCircleID(groupID)
        
        prepareForChannel(circleChannel!)
        
        client.subscribeToChannel(circleChannel, usingBlock: { data in
            //println("subscribeToChannel: \(data)")
            if let
                messageInfo = data as? JSONDictionary,
                messageType = messageInfo["message_type"] as? String {
                    
                    switch messageType {
                        
                    case FayeService.MessageType.Default.rawValue:
                        if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                            self.saveMessageWithMessageInfo(messageDataInfo)
                        }
                        
                    case FayeService.MessageType.Instant.rawValue:
                        if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                            
                            if let
                                user = messageDataInfo["user"] as? JSONDictionary,
                                userID = user["id"] as? String,
                                state = messageDataInfo["state"] as? Int {
                                    
                                    if let instantStateType = InstantStateType(rawValue: state) {
                                        self.delegate?.fayeRecievedInstantStateType(instantStateType, userID: userID)
                                    }
                            }
                        }
                        
                    case FayeService.MessageType.Read.rawValue:
                        if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                            
                            if let
                                //recipientID = messageDataInfo["recipient_id"] as? String,
                                messageID = messageDataInfo["id"] as? String {
                                    
                                    println("Mark Message \(messageID) As Read")
                                    
                                    guard let realm = try? Realm() else {
                                        return
                                    }
                                    
                                    if let message = messageWithMessageID(messageID, inRealm: realm) {
                                        realm.write {
                                            message.sendState = MessageSendState.Read.rawValue
                                        }
                                        
                                        NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                                    }
                            }
                        }
                    default:
                        println("Recieved unknow message type")
                    }
            }
        })
    }

    func startConnect() {
        if
            let userID = YepUserDefaults.userID.value {
                
                let personalChannel = personalChannelWithUserID(userID)

                println("Will Subscribe \(personalChannel)")
                
                prepareForChannel("connect")
                
                prepareForChannel("handshake")
                
                prepareForChannel(personalChannel!)

                client.subscribeToChannel(personalChannel, usingBlock: { data in
                    //println("subscribeToChannel: \(data)")
                    if let
                        messageInfo = data as? JSONDictionary,
                        messageType = messageInfo["message_type"] as? String {

                            switch messageType {

                            case FayeService.MessageType.Default.rawValue:
                                if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                                    self.saveMessageWithMessageInfo(messageDataInfo)
                                }

                            case FayeService.MessageType.Instant.rawValue:
                                if let messageDataInfo = messageInfo["message"] as? JSONDictionary {

                                    if let
                                        user = messageDataInfo["user"] as? JSONDictionary,
                                        userID = user["id"] as? String,
                                        state = messageDataInfo["state"] as? Int {

                                            if let instantStateType = InstantStateType(rawValue: state) {
                                                self.delegate?.fayeRecievedInstantStateType(instantStateType, userID: userID)
                                            }
                                    }
                                }
                                
                            case FayeService.MessageType.Read.rawValue:
                                if let messageDataInfo = messageInfo["message"] as? JSONDictionary {
                                    
                                    if let
                                        //recipientID = messageDataInfo["recipient_id"] as? String,
                                        messageID = messageDataInfo["id"] as? String {
                                            
                                            println("Mark Message \(messageID) As Read")

                                            guard let realm = try? Realm() else {
                                                return
                                            }

                                            if let message = messageWithMessageID(messageID, inRealm: realm) {
                                                realm.write {
                                                    message.sendState = MessageSendState.Read.rawValue
                                                }
                                                
                                                NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                                            }
                                    }
                                }
                            default:
                                println("Recieved unknow message type")
                            }
                    }
                })

                client.connect()

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

    private func saveMessageWithMessageInfo(messageInfo: JSONDictionary) {
        //这里不用 realmQueue 是为了下面的通知同步，用了 realmQueue 可能导致数据更新慢于通知
        dispatch_async(dispatch_get_main_queue()) {
            
            guard let realm = try? Realm() else {
                return
            }

            syncMessageWithMessageInfo(messageInfo, inRealm: realm) { messageIDs in
                dispatch_async(dispatch_get_main_queue()) {
                    let object = ["messageIDs": messageIDs]
                    NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: object)
                }
            }
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
        
        if let
            userChannel = personalChannelWithUserID(userID),
            extensionData = extensionData() {

                let data: JSONDictionary = [
                    "api_version": "v1",
                    "message_type": messageType.rawValue,
                    "message": message
                ]

                client.sendMessage(data, toChannel: userChannel, usingExtension: extensionData, usingBlock: { message  in
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
