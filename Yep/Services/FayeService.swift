//
//  YepMessageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MZFayeClient
import Realm

enum FayeMessageType: Printable {
    case Default
    case Instant
    
    var description: String {
        switch self {
        case .Default:
            return "message"
        case .Instant:
            return "instant_state"
        }
    }
}

enum FayeInstantStateType: Printable {
    case Default
    case Text
    case Audio
    
    var description: String {
        switch self {
        case .Default:
            return "Default"
        case .Text:
            return "typing"
        case .Audio:
            return "recording"
        }
    }
}

public protocol FayeServiceDelegate {
    /**
    * Current Typing Status
    *
    */
    func fayeRecievedCurrentStatus(status: String, userID: String)
    
}

class FayeService: NSObject, MZFayeClientDelegate {

    static let sharedManager = FayeService()

    let client: MZFayeClient
    
    var delegate:FayeServiceDelegate?
    
    override init() {

        client = MZFayeClient(URL:fayeBaseURL)
        
        super.init()
        
        client.delegate = self
        
    }

    // MARK: Public

    func startConnect() {
        if
            let extensionData = extensionData(),
            let userID = YepUserDefaults.userID.value {
                
                let personalChannel = personalChannelWithUserID(userID)

                println("Will Subscribe \(personalChannel)")
                client.setExtension(extensionData, forChannel: personalChannel)
                client.setExtension(extensionData, forChannel: "handshake")
                client.setExtension(extensionData, forChannel: "connect")

                client.subscribeToChannel(personalChannel, usingBlock: { data in
//                    println("subscribeToChannel: \(data)")
                    let messageInfo = data as! JSONDictionary
                    if let messageType = messageInfo["message_type"] as? String {
                        
                        switch messageType {
                            
                            case FayeMessageType.Default.description:
                                if let messageDataInfo = messageInfo["message"] as? [String: AnyObject] {
                                    self.saveMessageWithMessageInfo(messageDataInfo)
                                }
                                
                            case FayeMessageType.Instant.description:
                                if let messageDataInfo = messageInfo["message"] as? [String: AnyObject] {
                                    let user = messageDataInfo["user"] as! [String: AnyObject]
                                    let userID = user["id"] as! String
                                    let state = messageDataInfo["state"] as! String
                                    self.delegate?.fayeRecievedCurrentStatus(state, userID: userID)
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
        return "/users/\(userID)/messages"
    }
    
    private func circleChannelWithCircleID(circleID: String) -> String?{
        return "/circles/\(circleID)/messages"
    }

    private func saveMessageWithMessageInfo(messageInfo: JSONDictionary) {
        //这里不用 realmQueue 是为了下面的通知同步，用了 realmQueue 可能导致数据更新慢于通知
        let realm = RLMRealm.defaultRealm()
        syncMessageWithMessageInfo(messageInfo, inRealm: realm) {
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: nil)
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
    
    func sendPrivateMessage(message: JSONDictionary, messageType: FayeMessageType, userID: String, completion: (success: Bool, messageID: String?)->() ) {
        
        if let
            userChannel = personalChannelWithUserID(userID),
            extensionData = extensionData(){
                
                let data: [String: AnyObject] = [
                    "api_version": "v1",
                    "message_type": messageType.description,
                    "message": message
                ]
                
            client.sendMessage(data, toChannel: userChannel, usingExtension: extensionData, usingBlock: { message  in
                println("sendPrivateMessage \(message.successful)")

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
            println("Can NOT sendPrivateMessage, not circleChannel or extensionData")

            completion(success: false, messageID: nil)
        }
    }
    
    func sendGroupMessage(message: JSONDictionary, circleID: String, completion: (success: Bool, messageID: String?) -> Void)  {
        
        if let
            circleChannel = circleChannelWithCircleID(circleID),
            extensionData = extensionData() {
                
                let data: [String: AnyObject] = [
                    "api_version": "v1",
                    "message_type": "message",
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
