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

    func playAudio(of message: Message?) {

        AudioBot.stopPlay()

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer, let playingMessage = YepAudioService.sharedManager.playingMessage, audioPlayer.isPlaying {

            audioPlayer.pause()

            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                playbackTimer.invalidate()
            }

            if let sender = playingMessage.fromFriend, let playingMessageIndex = messages.index(of: playingMessage) {

                let indexPath = IndexPath(item: playingMessageIndex - displayedMessagesRange.location, section: Section.message.rawValue)

                if sender.friendState != UserFriendState.me.rawValue {
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatLeftAudioCell {
                        cell.playing = false
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatRightAudioCell {
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
                let playbackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(ConversationViewController.updateAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                YepAudioService.sharedManager.playbackTimer = playbackTimer
            }

        } else {
            YepAudioService.sharedManager.resetToDefault()
        }
    }

    @objc fileprivate func updateAudioPlaybackProgress(_ timer: Timer) {

        func updateAudioCell(for message: Message, withCurrentTime currentTime: TimeInterval) {

            guard let messageIndex = messages.index(of: message) else {
                return
            }

            let indexPath = IndexPath(item: messageIndex - displayedMessagesRange.location, section: Section.message.rawValue)

            if let sender = message.fromFriend {
                if sender.friendState != UserFriendState.me.rawValue {
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatLeftAudioCell {
                        cell.audioPlayedDuration = currentTime
                    }

                } else {
                    if let cell = conversationCollectionView.cellForItem(at: indexPath) as? ChatRightAudioCell {
                        cell.audioPlayedDuration = currentTime
                    }
                }
            }
        }

        if let audioPlayer = YepAudioService.sharedManager.audioPlayer, let playingMessage = YepAudioService.sharedManager.playingMessage {

            let currentTime = audioPlayer.currentTime

            setAudioPlayedDuration(currentTime, ofMessage: playingMessage)
            
            updateAudioCell(for: playingMessage, withCurrentTime: currentTime)
        }
    }
}

extension ConversationViewController: AVAudioPlayerDelegate {

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {

        println("audioPlayerBeginInterruption")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {

        println("audioPlayerDecodeErrorDidOccur")
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

        UIDevice.current.isProximityMonitoringEnabled = false

        println("audioPlayerDidFinishPlaying \(flag)")

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        if let playingMessage = YepAudioService.sharedManager.playingMessage {
            setAudioPlayedDuration(0, ofMessage: playingMessage)
            println("setAudioPlayedDuration to 0")
        }

        func nextUnplayedAudioMessageFrom(_ message: Message) -> Message? {

            if let index = messages.index(of: message) {
                for i in (index + 1)..<messages.count {
                    if let message = messages[safe: i], let friend = message.fromFriend {
                        if friend.friendState != UserFriendState.me.rawValue {
                            if (message.mediaType == MessageMediaType.audio.rawValue) && (message.mediaPlayed == false) {
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
            playAudio(of: message)

        } else {
            YepAudioService.sharedManager.resetToDefault()
        }
    }
}

