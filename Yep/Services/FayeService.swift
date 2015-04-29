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

class FayeService: NSObject, MZFayeClientDelegate {

    static let sharedManager = FayeService()

    let client: MZFayeClient
    
    override init() {

        client = MZFayeClient(URL:NSURL(string: "ws://faye.catchchatchina.com/faye"))
        
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
                    let messageType = messageInfo["message_type"] as! String
                    if messageType == "message" {
                        if let messageDataInfo = messageInfo["message"] as? [String: AnyObject] {
                            self.saveMessageWithMessageInfo(messageDataInfo)
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
    
    func sendPrivateMessage(message: JSONDictionary, userID: String) {
        
        if let userChannel = personalChannelWithUserID(userID),
            let extensionData = extensionData(){
                
                var data: [String: AnyObject] = [
                        "api_version" : "v1",
                        "message_type" : "message",
                        "message" : message
                ]
                
            client.sendMessage(data, toChannel: userChannel, usingExtension: extensionData)
        }

    }
    
    func sendGroupMessage(message: JSONDictionary, circleID: String)  {
        
        if let circleChannel = circleChannelWithCircleID(circleID),
            let extensionData = extensionData(){
                
                var data: [String: AnyObject] = [
                    "api_version" : "v1",
                    "message_type" : "message",
                    "message" : message
                ]
                
                client.sendMessage(data, toChannel: circleChannel, usingExtension: extensionData)
        }
    }

    
}
