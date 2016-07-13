//
//  ChatViewController+UIImagePickerControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/7/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MobileCoreServices.UTType
import YepKit
import YepNetworking

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            switch mediaType {

            case String(kUTTypeImage):

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                    let fixedSize = image.yep_fixedSize

                    // resize to smaller, not need fixRotation

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: .High) {
                        send(image: fixedImage)
                    }
                }

            case String(kUTTypeMovie):

                if let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL {
                    println("videoURL \(videoURL)")
                    send(videoWithVideoURL: videoURL)
                }

            default:
                break
            }
        }

        dismissViewControllerAnimated(true, completion: nil)
    }

}

