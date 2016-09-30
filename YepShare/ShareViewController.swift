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

    fileprivate var skill: Skill? {
        didSet {
            if let skill = skill {
                channelItem.value = skill.localName
            } else {
                channelItem.value = String.trans_titleDefault
            }
        }
    }

    lazy var channelItem: SLComposeSheetConfigurationItem = {

        let item = SLComposeSheetConfigurationItem()
        item?.title = String.trans_titleChannel
        item?.value = NSLocalizedString("Default", comment: "")
        item?.tapHandler = { [weak self] in
            self?.performSegue(withIdentifier: "presentChooseChannel", sender: nil)
        }

        return item!
    }()

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else { return }

        switch identifier {

        case "presentChooseChannel":

            let nvc = segue.destination as! UINavigationController
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

        title = String.trans_titleNewFeed

        Realm.Configuration.defaultConfiguration = realmConfig()

        YepNetworking.Manager.accessToken = {
            return YepUserDefaults.v1AccessToken.value
        }
    }

    override func isContentValid() -> Bool {
        return !(contentText ?? "").isEmpty || !webURLs.isEmpty
    }

    var webURLs: [URL] = []
    var images: [UIImage] = []
    var fileURLs: [URL] = []

    override func presentationAnimationDidFinish() {

        webURLsFromExtensionContext(extensionContext!) { [weak self] webURLs in
            self?.webURLs = webURLs
            //print("webURLs: \(self?.webURLs)")
        }

        imagesFromExtensionContext(extensionContext!) { [weak self] images in
            self?.images = images
            //print("images: \(self?.images)")
        }

        fileURLsFromExtensionContext(extensionContext!) { [weak self] fileURLs in
            self?.fileURLs = fileURLs
            //print("fileURLs: \(self?.fileURLs)")
        }
    }

    override func didSelectPost() {

        guard let avatarURLString = YepUserDefaults.avatarURLString.value, !avatarURLString.isEmpty else {

            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)

            return
        }

        let shareType: ShareType
        let body = contentText ?? ""
        if let fileURL = fileURLs.first, fileURL.pathExtension == FileExtension.m4a.rawValue {
            shareType = .audio(body: body, fileURL: fileURL)
        } else if let URL = webURLs.first {
            shareType = .url(body: body, URL: URL)
        } else if !images.isEmpty {
            shareType = .images(body: body, images: images)
        } else {
            shareType = .plainText(body: body)
        }

        postFeed(shareType) { [weak self] finish in
            //print("postFeed \(shareType) finish: \(finish)")
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {

        return [channelItem]
    }

    enum ShareType {

        case plainText(body: String)
        case audio(body: String, fileURL: Foundation.URL)
        case url(body: String, URL: Foundation.URL)
        case images(body: String, images: [UIImage])

        var body: String {
            switch self {
            case .plainText(let body): return body
            case .audio(let body, _): return body
            case .url(let body, _): return body
            case .images(let body, _): return body
            }
        }
    }

    fileprivate func postFeed(_ shareType: ShareType, completion: @escaping (_ finish: Bool) -> Void) {

        var message = shareType.body
        var kind: FeedKind = .Text
        var attachments: [JSONDictionary]?

        let doCreateFeed: () -> Void = { [weak self] in

            let coordinate = YepUserDefaults.userCoordinate

            createFeedWithKind(kind, message: message, attachments: attachments, coordinate: coordinate, skill: self?.skill, allowComment: true, failureHandler: { reason, errorMessage in
                SafeDispatch.async {
                    completion(false)
                }

            }, completion: { data in
                //print("createFeedWithKind: \(data)")

                SafeDispatch.async {
                    completion(true)
                }
            })
        }

        switch shareType {

        case .plainText:

            doCreateFeed()

        case .audio(_, let fileURL):

            let tempPath = NSTemporaryDirectory().appending("\(UUID().uuidString).\(FileExtension.m4a.rawValue)")
            let tempURL = URL(fileURLWithPath: tempPath)
            try! FileManager.default.copyItem(at: fileURL, to: tempURL)

            let audioAsset = AVURLAsset(url: tempURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            /*
            var audioSamples: [CGFloat] = []
            var audioSampleMax: CGFloat = 0
            do {
                let reader = try! AVAssetReader(asset: audioAsset)
                let track = audioAsset.tracks.first!
                let outputSettings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false,
                ]
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
                reader.add(output)

                var sampleRate: Double = 0
                var channelCount: Int = 0
                for item in track.formatDescriptions as! [CMAudioFormatDescription] {
                    let formatDescription = CMAudioFormatDescriptionGetStreamBasicDescription(item)
                    sampleRate = Double(formatDescription!.pointee.mSampleRate)
                    channelCount = Int(formatDescription!.pointee.mChannelsPerFrame)
                    //print("sampleRate: \(sampleRate)")
                    //print("channelCount: \(channelCount)")
                }

                let bytesPerSample = channelCount * 2

                reader.startReading()

                func decibel(_ amplitude: CGFloat) -> CGFloat {
                    return 20 * log10(abs(amplitude) / 32767)
                }

                while reader.status == .reading {
                    guard let trachOutput = reader.outputs.first else { continue }
                    guard let sampleBuffer = trachOutput.copyNextSampleBuffer() else { continue }
                    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
                    let length = CMBlockBufferGetDataLength(blockBuffer)
                    let data = NSMutableData(length: length)!
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, data.mutableBytes)
                    //UnsafeMutableRawPointer(data.mutableBytes)
                    let samples = UnsafeMutableRawPointer(data.mutableBytes)
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
            */

            let fakeAudioSamples: [CGFloat] = (0..<Int(audioDuration * 10)).map({ _ in
                CGFloat(arc4random() % 100) / 100
            })
            let finalCount = limitedAudioSamplesCount(fakeAudioSamples.count)
            let limitedAudioSamples = averageSamplingFrom(fakeAudioSamples, withCount: finalCount)

            let audioMetaDataInfo: JSONDictionary = [
                Config.MetaData.audioDuration: audioDuration,
                Config.MetaData.audioSamples: limitedAudioSamples,
            ]

            var metaDataString = ""
            if let audioMetaData = try? JSONSerialization.data(withJSONObject: audioMetaDataInfo, options: []) {
                if let audioMetaDataString = String(data: audioMetaData, encoding: .utf8) {
                    metaDataString = audioMetaDataString
                }
            }

            let uploadVoiceGroup = DispatchGroup()

            uploadVoiceGroup.enter()

            let source: UploadAttachment.Source = .filePath(fileURL.path)

            let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .m4a, metaDataString: metaDataString)

            tryUploadAttachment(uploadAttachment, failureHandler: { (reason, errorMessage) in
                SafeDispatch.async {
                    uploadVoiceGroup.leave()
                }

            }, completion: { uploadedAttachment in

                let audioInfo: JSONDictionary = [
                    "id": uploadedAttachment.ID
                ]

                attachments = [audioInfo]

                SafeDispatch.async {
                    uploadVoiceGroup.leave()
                }
            })

            uploadVoiceGroup.notify(queue: DispatchQueue.main) {

                kind = .Audio
                
                doCreateFeed()
            }

        case .url(let body, let URL):

            let parseOpenGraphGroup = DispatchGroup()

            parseOpenGraphGroup.enter()

            openGraphWithURL(URL, failureHandler: { reason, errorMessage in
                SafeDispatch.async {
                    parseOpenGraphGroup.leave()
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
                    parseOpenGraphGroup.leave()
                }
            })

            parseOpenGraphGroup.notify(queue: DispatchQueue.main) {

                let realBody: String
                if !body.isEmpty {
                    realBody = body + " " + URL.absoluteString
                } else {
                    realBody = URL.absoluteString
                }

                message = realBody

                doCreateFeed()
            }

        case .images(_, let mediaImages):

            let uploadImagesQueue = OperationQueue()
            var uploadAttachmentOperations = [UploadAttachmentOperation]()
            var uploadedAttachments = [UploadedAttachment]()

            mediaImages.forEach({ image in

                let fixedSize = image.yep_fixedSize

                // resize to smaller, not need fixRotation

                if let image = image.resizeToSize(fixedSize, withInterpolationQuality: .high), let imageData = UIImageJPEGRepresentation(image, 0.95) {

                    let source: UploadAttachment.Source = .data(imageData)
                    let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: false)
                    let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .jpeg, metaDataString: metaDataString)

                    let operation = UploadAttachmentOperation(uploadAttachment: uploadAttachment) { result in
                        switch result {
                        case .failed(let errorMessage):
                            print("UploadAttachmentOperation errorMessage: \(errorMessage)")
                        case .success(let uploadedAttachment):
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

            let uploadFinishOperation = BlockOperation {

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

    fileprivate func webURLsFromExtensionContext(_ extensionContext: NSExtensionContext, completion: @escaping (_ webURLs: [URL]) -> Void) {

        var webURLs: [URL] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion([])
        }

        let URLTypeIdentifier = kUTTypeURL as String

        let group = DispatchGroup()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(URLTypeIdentifier) {

                    group.enter()

                    attachment.loadItem(forTypeIdentifier: URLTypeIdentifier, options: nil) { secureCoding, error in

                        if let url = secureCoding as? URL, !url.isFileURL {
                            webURLs.append(url)
                        }

                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(webURLs)
        }
    }

    fileprivate func imagesFromExtensionContext(_ extensionContext: NSExtensionContext, completion: @escaping (_ images: [UIImage]) -> Void) {

        var images: [UIImage] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion([])
        }

        let imageTypeIdentifier = kUTTypeImage as String

        let group = DispatchGroup()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(imageTypeIdentifier) {

                    group.enter()

                    attachment.loadItem(forTypeIdentifier: imageTypeIdentifier, options: nil) { secureCoding, error in

                        if let fileURL = secureCoding as? URL, let image = UIImage(contentsOfFile: fileURL.path) {
                            images.append(image)
                        }

                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(images)
        }
    }

    fileprivate func fileURLsFromExtensionContext(_ extensionContext: NSExtensionContext, completion: @escaping (_ fileURLs: [URL]) -> Void) {

        var fileURLs: [URL] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion([])
        }

        let fileURLTypeIdentifier = kUTTypeFileURL as String

        let group = DispatchGroup()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(fileURLTypeIdentifier) {

                    group.enter()

                    attachment.loadItem(forTypeIdentifier: fileURLTypeIdentifier, options: nil) { secureCoding, error in

                        if let url = secureCoding as? URL {
                            fileURLs.append(url)
                        }

                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(fileURLs)
        }
    }
}

