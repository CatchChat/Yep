//
//  ShareViewController.swift
//  YepShare
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Social
import AVFoundation
import AudioToolbox
import MobileCoreServices.UTType
import YepKit
import YepNetworking
import OpenGraph
import RealmSwift

class ShareViewController: SLComposeServiceViewController {

    private var skill: Skill? {
        didSet {
            if let skill = skill {
                channelItem.value = skill.localName
            } else {
                channelItem.value = NSLocalizedString("Default", comment: "")
            }
        }
    }

    lazy var channelItem: SLComposeSheetConfigurationItem = {

        let item = SLComposeSheetConfigurationItem()
        item.title = NSLocalizedString("Channel", comment: "")
        item.value = NSLocalizedString("Default", comment: "")
        item.tapHandler = { [weak self] in
            self?.performSegueWithIdentifier("presentChooseChannel", sender: nil)
        }

        return item
    }()

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else { return }

        switch identifier {

        case "presentChooseChannel":

            let nvc = segue.destinationViewController as! UINavigationController
            let vc = nvc.topViewController as! ChooseChannelViewController

            vc.currentPickedSkill = skill

            vc.pickedSkillAction = { [weak self] skill in
                self?.skill = skill
            }

        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Feed", comment: "")

        Realm.Configuration.defaultConfiguration = realmConfig()

        YepNetworking.Manager.accessToken = {
            return YepUserDefaults.v1AccessToken.value
        }
    }

    override func isContentValid() -> Bool {
        return !(contentText ?? "").isEmpty || !webURLs.isEmpty
    }

    var webURLs: [NSURL] = []
    var images: [UIImage] = []
    var fileURLs: [NSURL] = []

    override func presentationAnimationDidFinish() {

        webURLsFromExtensionContext(extensionContext!) { [weak self] webURLs in
            self?.webURLs = webURLs

            print("webURLs: \(self?.webURLs)")
        }

        imagesFromExtensionContext(extensionContext!) { [weak self] images in
            self?.images = images

            print("images: \(self?.images)")
        }

        fileURLsFromExtensionContext(extensionContext!) { [weak self] fileURLs in
            self?.fileURLs = fileURLs

            print("fileURLs: \(self?.fileURLs)")
        }
    }

    override func didSelectPost() {

        guard let avatarURLString = YepUserDefaults.avatarURLString.value where !avatarURLString.isEmpty else {

            extensionContext?.completeRequestReturningItems([], completionHandler: nil)

            return
        }

        let shareType: ShareType
        let body = contentText ?? ""
        if let fileURL = fileURLs.first where fileURL.pathExtension == "m4a" {
            shareType = .Audio(body: body, fileURL: fileURL)
        } else if let URL = webURLs.first {
            shareType = .URL(body: body, URL: URL)
        } else if !images.isEmpty {
            shareType = .Images(body: body, images: images)
        } else {
            shareType = .PlainText(body: body)
        }

        postFeed(shareType) { [weak self] finish in

            print("postFeed \(shareType) finish: \(finish)")

            self?.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
        }
    }

    override func configurationItems() -> [AnyObject]! {

        return [channelItem]
    }

    enum ShareType {

        case PlainText(body: String)
        case Audio(body: String, fileURL: NSURL)
        case URL(body: String, URL: NSURL)
        case Images(body: String, images: [UIImage])

        var body: String {
            switch self {
            case .PlainText(let body): return body
            case .Audio(let body, _): return body
            case .URL(let body, _): return body
            case .Images(let body, _): return body
            }
        }
    }

    private func postFeed(shareType: ShareType, completion: (finish: Bool) -> Void) {

        var message = shareType.body
        var kind: FeedKind = .Text
        var attachments: [JSONDictionary]?

        let doCreateFeed: () -> Void = { [weak self] in

            let coordinate = YepUserDefaults.userCoordinate

            createFeedWithKind(kind, message: message, attachments: attachments, coordinate: coordinate, skill: self?.skill, allowComment: true, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                SafeDispatch.async {
                    completion(finish: false)
                }

            }, completion: { data in
                //print("createFeedWithKind: \(data)")

                SafeDispatch.async {
                    completion(finish: true)
                }
            })
        }

        switch shareType {

        case .PlainText:

            doCreateFeed()

        case .Audio(_, let fileURL):

            let tempPath = NSTemporaryDirectory().stringByAppendingString("\(NSUUID().UUIDString).m4a")
            let tempURL = NSURL(fileURLWithPath: tempPath)
            try! NSFileManager.defaultManager().copyItemAtURL(fileURL, toURL: tempURL)

            let audioAsset = AVURLAsset(URL: tempURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            var audioSamples: [CGFloat] = []
            var audioSampleMax: CGFloat = 0
            do {
                let reader = try! AVAssetReader(asset: audioAsset)
                let track = audioAsset.tracks.first!
                let outputSettings: [String: AnyObject] = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false,
                ]
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
                reader.addOutput(output)

                var sampleRate: Double = 0
                var channelCount: Int = 0
                for item in track.formatDescriptions as! [CMAudioFormatDescription] {
                    let formatDescription = CMAudioFormatDescriptionGetStreamBasicDescription(item)
                    sampleRate = Double(formatDescription.memory.mSampleRate)
                    channelCount = Int(formatDescription.memory.mChannelsPerFrame)
                    //print("sampleRate: \(sampleRate)")
                    //print("channelCount: \(channelCount)")
                }

                let bytesPerSample = channelCount * 2

                reader.startReading()

                func decibel(amplitude: CGFloat) -> CGFloat {
                    return 20 * log10(abs(amplitude) / 32767)
                }

                while reader.status == AVAssetReaderStatus.Reading {
                    guard let trachOutput = reader.outputs.first else { continue }
                    guard let sampleBuffer = trachOutput.copyNextSampleBuffer() else { continue }
                    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
                    let length = CMBlockBufferGetDataLength(blockBuffer)
                    let data = NSMutableData(length: length)!
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, data.mutableBytes)
                    let samples = UnsafeMutablePointer<Int16>(data.mutableBytes)
                    let samplesCount = length / bytesPerSample
                    if samplesCount > 0 {
                        let left = samples.memory
                        let d = abs(decibel(CGFloat(left)))
                        guard d.isNormal else {
                            continue
                        }
                        audioSamples.append(d)
                        if d > audioSampleMax {
                            audioSampleMax = d
                        }
                    }
                }

                audioSamples = audioSamples.map({ $0 / audioSampleMax })
            }

            let finalCount = limitedAudioSamplesCount(audioSamples.count)
            let limitedAudioSamples = averageSamplingFrom(audioSamples, withCount: finalCount)

            /*
            let fakeAudioSamples: [CGFloat] = (0..<Int(audioDuration * 10)).map({ _ in
                CGFloat(arc4random() % 100) / 100
            })
            let finalCount = limitedAudioSamplesCount(fakeAudioSamples.count)
            let limitedAudioSamples = averageSamplingFrom(fakeAudioSamples, withCount: finalCount)
             */

            let audioMetaDataInfo = [
                Config.MetaData.audioDuration: audioDuration,
                Config.MetaData.audioSamples: limitedAudioSamples,
            ]

            var metaDataString = ""
            if let audioMetaData = try? NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: []) {
                if let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String {
                    metaDataString = audioMetaDataString
                }
            }

            let uploadVoiceGroup = dispatch_group_create()

            dispatch_group_enter(uploadVoiceGroup)

            let source: UploadAttachment.Source = .FilePath(fileURL.path!)

            let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .M4A, metaDataString: metaDataString)

            tryUploadAttachment(uploadAttachment, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                SafeDispatch.async {
                    dispatch_group_leave(uploadVoiceGroup)
                }

            }, completion: { uploadedAttachment in

                let audioInfo: JSONDictionary = [
                    "id": uploadedAttachment.ID
                ]

                attachments = [audioInfo]

                SafeDispatch.async {
                    dispatch_group_leave(uploadVoiceGroup)
                }
            })

            dispatch_group_notify(uploadVoiceGroup, dispatch_get_main_queue()) {

                kind = .Audio
                
                doCreateFeed()
            }

        case .URL(let body, let URL):

            let parseOpenGraphGroup = dispatch_group_create()

            dispatch_group_enter(parseOpenGraphGroup)

            openGraphWithURL(URL, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                SafeDispatch.async {
                    dispatch_group_leave(parseOpenGraphGroup)
                }

            }, completion: { openGraph in

                kind = .URL

                let URLInfo = [
                    "url": openGraph.URL.absoluteString,
                    "site_name": (openGraph.siteName ?? "").yepshare_truncatedForFeed,
                    "title": (openGraph.title ?? "").yepshare_truncatedForFeed,
                    "description": (openGraph.description ?? "").yepshare_truncatedForFeed,
                    "image_url": openGraph.previewImageURLString ?? "",
                ]

                attachments = [URLInfo]

                SafeDispatch.async {
                    dispatch_group_leave(parseOpenGraphGroup)
                }
            })

            dispatch_group_notify(parseOpenGraphGroup, dispatch_get_main_queue()) {

                let realBody: String
                if !body.isEmpty {
                    realBody = body + " " + URL.absoluteString
                } else {
                    realBody = URL.absoluteString
                }

                message = realBody

                doCreateFeed()
            }

        case .Images(_, let mediaImages):

            let uploadImagesQueue = NSOperationQueue()
            var uploadAttachmentOperations = [UploadAttachmentOperation]()
            var uploadedAttachments = [UploadedAttachment]()

            mediaImages.forEach({ image in

                let fixedSize = image.yep_fixedSize

                // resize to smaller, not need fixRotation

                if let image = image.resizeToSize(fixedSize, withInterpolationQuality: .High), imageData = UIImageJPEGRepresentation(image, 0.95) {

                    let source: UploadAttachment.Source = .Data(imageData)
                    let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: false)
                    let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .JPEG, metaDataString: metaDataString)

                    let operation = UploadAttachmentOperation(uploadAttachment: uploadAttachment) { result in
                        switch result {
                        case .Failed(let errorMessage):
                            print("UploadAttachmentOperation errorMessage: \(errorMessage)")
                        case .Success(let uploadedAttachment):
                            uploadedAttachments.append(uploadedAttachment)
                        }
                    }

                    uploadAttachmentOperations.append(operation)
                }
            })

            if uploadAttachmentOperations.count > 1 {
                for i in 1..<uploadAttachmentOperations.count {
                    let previousOperation = uploadAttachmentOperations[i-1]
                    let currentOperation = uploadAttachmentOperations[i]

                    currentOperation.addDependency(previousOperation)
                }
            }

            let uploadFinishOperation = NSBlockOperation {

                if !uploadedAttachments.isEmpty {

                    let imageInfos: [JSONDictionary] = uploadedAttachments.map({
                        ["id": $0.ID]
                    })

                    attachments = imageInfos

                    kind = .Image
                }

                doCreateFeed()
            }
            
            if let lastUploadAttachmentOperation = uploadAttachmentOperations.last {
                uploadFinishOperation.addDependency(lastUploadAttachmentOperation)
            }
            
            uploadImagesQueue.addOperations(uploadAttachmentOperations, waitUntilFinished: false)
            uploadImagesQueue.addOperation(uploadFinishOperation)
        }
    }
}

extension ShareViewController {

    private func webURLsFromExtensionContext(extensionContext: NSExtensionContext, completion: (webURLs: [NSURL]) -> Void) {

        var webURLs: [NSURL] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion(webURLs: [])
        }

        let URLTypeIdentifier = kUTTypeURL as String

        let group = dispatch_group_create()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(URLTypeIdentifier) {

                    dispatch_group_enter(group)

                    attachment.loadItemForTypeIdentifier(URLTypeIdentifier, options: nil) { secureCoding, error in

                        if let url = secureCoding as? NSURL where !url.fileURL {
                            webURLs.append(url)
                        }

                        dispatch_group_leave(group)
                    }
                }
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(webURLs: webURLs)
        }
    }

    private func imagesFromExtensionContext(extensionContext: NSExtensionContext, completion: (images: [UIImage]) -> Void) {

        var images: [UIImage] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion(images: [])
        }

        let imageTypeIdentifier = kUTTypeImage as String

        let group = dispatch_group_create()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(imageTypeIdentifier) {

                    dispatch_group_enter(group)

                    attachment.loadItemForTypeIdentifier(imageTypeIdentifier, options: nil) { secureCoding, error in

                        if let fileURL = secureCoding as? NSURL, image = UIImage(contentsOfFile: fileURL.path!) {
                            images.append(image)
                        }

                        dispatch_group_leave(group)
                    }
                }
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(images: images)
        }
    }

    private func fileURLsFromExtensionContext(extensionContext: NSExtensionContext, completion: (fileURLs: [NSURL]) -> Void) {

        var fileURLs: [NSURL] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion(fileURLs: [])
        }

        let fileURLTypeIdentifier = kUTTypeFileURL as String

        let group = dispatch_group_create()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(fileURLTypeIdentifier) {

                    dispatch_group_enter(group)

                    attachment.loadItemForTypeIdentifier(fileURLTypeIdentifier, options: nil) { secureCoding, error in

                        if let url = secureCoding as? NSURL {
                            fileURLs.append(url)
                        }

                        dispatch_group_leave(group)
                    }
                }
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(fileURLs: fileURLs)
        }
    }
}

