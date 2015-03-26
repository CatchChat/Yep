//
//  YepMessageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MZFayeClient

class FayeService: NSObject, MZFayeClientDelegate {

    static let sharedManager = FayeService()

    let client: MZFayeClient

    override init() {

        client = MZFayeClient(URL:NSURL(string: "http://faye.catchchatchina.com/faye"))
        
        super.init()
        
        client.delegate = self
    }

    // MARK: Public

    func startConnect() {
        if
            let v1AccessToken = YepUserDefaults.v1AccessToken(),
            let userID = YepUserDefaults.userID() {
                let extensionData = [
                    "access_token": v1AccessToken,
                    "mobile": "18620855007",
                    "phone_code": "86"
                ]

                let personalChannel = personalChannelWithUserID(userID)

                println("Will Subscribe \(personalChannel)")
                client.setExtension(extensionData, forChannel: personalChannel)
                client.connect()
                client.subscribeToChannel(personalChannel)


        } else {
            println("FayeClient start failed!!!!")
        }
    }

    // MARK: Private

    private func personalChannelWithUserID(userID: String) -> String {
        return "/users/\(userID)/messages"
    }

    // MARK: MZFayeClientDelegate
    
    func fayeClient(client: MZFayeClient!, didConnectToURL url: NSURL!) {
        println("fayeClient didConnectToURL \(url)")
    }
    
    func fayeClient(client: MZFayeClient!, didDisconnectWithError error: NSError!) {
        println("fayeClient didDisconnectWithError \(error.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didFailDeserializeMessage message: [NSObject : AnyObject]!, withError error: NSError!) {
        println("fayeClient didFailDeserializeMessage \(error.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didFailWithError error: NSError!) {
        println("fayeClient didFailWithError \(error.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didReceiveMessage messageData: [NSObject : AnyObject]!, fromChannel channel: String!) {
        println("fayeClient didReceiveMessage \(messageData.description)")
    }
    
    func fayeClient(client: MZFayeClient!, didSubscribeToChannel channel: String!) {
        println("fayeClient didSubscribeToChannel \(channel)")
    }
    
    func fayeClient(client: MZFayeClient!, didUnsubscribeFromChannel channel: String!) {
        println("fayeClient didUnsubscribeFromChannel \(channel)")
    }
    
    
}
