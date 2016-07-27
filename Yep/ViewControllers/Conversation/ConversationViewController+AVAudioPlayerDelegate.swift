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
import AudioBot

extension ConversationViewController {

    func playMessageAudioWithMessage(message: Message?) {

        AudioBot.stopPlay()

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer, playingMessage = YepAudioService.sharedManager.playingMessage where audioPlayer.playing {

            audioPlayer.pause()

            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                playbackTimer.invalidate()
            }

            if let sender = playingMessage.fromFriend, playingMessageIndex = messages.indexOf(playingMessage) {

                let indexPath = NSIndexPath(forItem: playingMessageIndex - displayedMessagesRange.location, inSection: Section.Message.rawValue)

                if sender.friendState != UserFriendState.Me.rawValue {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftAudioCell {
                        cell.playing = false
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightAudioCell {
                        cell.playing = false
                    }
                }
            }

            if let message = message {
                if message.messageID == playingMessage.messageID {
                    YepAudioService.sharedManager.resetToDefault()
                    return
                }
            }
        }

        if let message = message {
            let audioPlayedDuration = audioPlayedDurationOfMessage(message)
            
            YepAudioService.sharedManager.playAudioWithMessage(message, beginFromTime: audioPlayedDuration, delegate: self) {
                let playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: #selector(ConversationViewController.updateAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                YepAudioService.sharedManager.playbackTimer = playbackTimer
            }

        } else {
            YepAudioService.sharedManager.resetToDefault()
        }
    }

    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        func updateAudioCellOfMessage(message: Message, withCurrentTime currentTime: NSTimeInterval) {

            guard let messageIndex = messages.indexOf(message) else {
                return
            }

            let indexPath = NSIndexPath(forItem: messageIndex - displayedMessagesRange.location, inSection: Section.Message.rawValue)

            if let sender = message.fromFriend {
                if sender.friendState != UserFriendState.Me.rawValue {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatLeftAudioCell {
                        cell.audioPlayedDuration = currentTime
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItemAtIndexPath(indexPath) as? ChatRightAudioCell {
                        cell.audioPlayedDuration = currentTime
                    }
                }
            }
        }

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer, playingMessage = YepAudioService.sharedManager.playingMessage {

            let currentTime = audioPlayer.currentTime

            setAudioPlayedDuration(currentTime, ofMessage: playingMessage)
            
            updateAudioCellOfMessage(playingMessage, withCurrentTime: currentTime)
        }
    }
}

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

