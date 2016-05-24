//
//  ShareViewController.swift
//  YepShare
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices.UTType
import YepKit
import YepConfig
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
        return !(contentText ?? "").isEmpty || !urls.isEmpty
    }

    var urls: [NSURL] = []
    var images: [UIImage] = []

    override func presentationAnimationDidFinish() {

        urlsFromExtensionContext(extensionContext!) { [weak self] urls in
            self?.urls = urls

            print("urls: \(self?.urls)")
        }

        imagesFromExtensionContext(extensionContext!) { [weak self] images in
            self?.images = images

            print("images: \(self?.images)")
        }
    }

    override func didSelectPost() {

        let shareType: ShareType
        let body = contentText ?? ""
        if let URL = urls.first {
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
        case URL(body: String, URL: NSURL)
        case Images(body: String, images: [UIImage])

        var body: String {
            switch self {
            case .PlainText(let body): return body
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

            createFeedWithKind(kind, message: message, attachments: attachments, coordinate: nil, skill: self?.skill, allowComment: true, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    completion(finish: false)
                }

            }, completion: { data in
                print("createFeedWithKind: \(data)")

                dispatch_async(dispatch_get_main_queue()) {
                    completion(finish: true)
                }
            })
        }

        switch shareType {

        case .PlainText:

            doCreateFeed()

        case .URL(let body, let URL):

            let parseOpenGraphGroup = dispatch_group_create()

            dispatch_group_enter(parseOpenGraphGroup)

            openGraphWithURL(URL, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
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

                dispatch_async(dispatch_get_main_queue()) {
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

                let imageWidth = image.size.width
                let imageHeight = image.size.height

                let fixedImageWidth: CGFloat
                let fixedImageHeight: CGFloat

                if imageWidth > imageHeight {
                    fixedImageWidth = min(imageWidth, YepConfig.Media.imageWidth)
                    fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
                } else {
                    fixedImageHeight = min(imageHeight, YepConfig.Media.imageHeight)
                    fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
                }

                let fixedSize = CGSize(width: fixedImageWidth, height: fixedImageHeight)

                // resize to smaller, not need fixRotation

                if let image = image.resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.High), imageData = UIImageJPEGRepresentation(image, 0.95) {

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

    private func urlsFromExtensionContext(extensionContext: NSExtensionContext, completion: (urls: [NSURL]) -> Void) {

        var urls: [NSURL] = []

        guard let extensionItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return completion(urls: [])
        }

        let URLTypeIdentifier = kUTTypeURL as String

        let group = dispatch_group_create()

        for extensionItem in extensionItems {
            for attachment in extensionItem.attachments as! [NSItemProvider] {
                if attachment.hasItemConformingToTypeIdentifier(URLTypeIdentifier) {

                    dispatch_group_enter(group)

                    attachment.loadItemForTypeIdentifier(URLTypeIdentifier, options: nil) { secureCoding, error in

                        if let url = secureCoding as? NSURL {
                            urls.append(url)
                        }

                        dispatch_group_leave(group)
                    }
                }
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(urls: urls)
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
}

