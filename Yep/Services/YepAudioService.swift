//
//  YepAudioService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class YepAudioService: NSObject {
    
    static let sharedManager = YepAudioService()
    
    var audioRecorder: AVAudioRecorder!
    
    override init() {
        super.init()
        prepareAudioRecorderWithURL(newURL())
    }
    
    func prepareAudioRecorderWithURL(url: NSURL) {
        let settings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 64000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        var error: NSError?
        audioRecorder = AVAudioRecorder(URL: url, settings: settings as [NSObject : AnyObject], error: &error)
        if let e = error {
            println(e.localizedDescription)
        } else {
            audioRecorder.meteringEnabled = true
            audioRecorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        }
    }
    
    func newURL() -> NSURL {
        var newCacheURL = cacheURL()
        return newCacheURL.URLByAppendingPathComponent("\(randomStringWithLength(16)).aac")
    }
    
    func beginRecord() {
        
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                
                if (self.audioRecorder.recording){
                    self.audioRecorder.stop()
                }else{
                    self.audioRecorder.record()
                    println("Audio Record did begin")
                }

//                NSTimer.scheduledTimerWithTimeInterval(0.1,
//                    target:self,
//                    selector:"updateAudioMeter:",
//                    userInfo:nil,
//                    repeats:true)
            } else {
                println("Permission to record not granted")
            }
        })
    }
    
    func endRecord() {
        if (self.audioRecorder.recording){
            self.audioRecorder.stop()
        }
    }
}

func cacheURL() -> NSURL {
    return NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.CachesDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false, error: nil)!
}

func randomStringWithLength (len : Int) -> NSString {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    var randomString : NSMutableString = NSMutableString(capacity: len)
    
    for (var i=0; i < len; i++){
        var length = UInt32 (letters.length)
        var rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString
}
