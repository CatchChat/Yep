//
//  ConversationViewController+AVAudioPlayerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import YepKit

extension ConversationViewController: AVAudioPlayerDelegate {

    func audioPlayerBeginInterruption(player: AVAudioPlayer) {

        println("audioPlayerBeginInterruption")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {

        println("audioPlayerDecodeErrorDidOccur")
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        UIDevice.currentDevice().proximityMonitoringEnabled = false

        println("audioPlayerDidFinishPlaying \(flag)")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            setAudioPlayedDuration(0, ofMessage: playingMessage)
            println("setAudioPlayedDuration to 0")
        }

        func nextUnplayedAudioMessageFrom(message: Message) -> Message? {

            if let index = messages.indexOf(message) {
                for i in (index + 1)..<messages.count {
                    if let message = messages[safe: i], friend = message.fromFriend {
                        if friend.friendState != UserFriendState.Me.rawValue {
                            if (message.mediaType == MessageMediaType.Audio.rawValue) && (message.mediaPlayed == false) {
                                return message
                            }
                        }
                    }
                }
            }

            return nil
        }

        // 尝试播放下一个未播放过的语音消息
        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            let message = nextUnplayedAudioMessageFrom(playingMessage)
            playMessageAudioWithMessage(message)

        } else {
            YepAudioService.sharedManager.resetToDefault()
        }
    }

    func audioPlayerEndInterruption(player: AVAudioPlayer) {

        println("audioPlayerEndInterruption")
    }
}

