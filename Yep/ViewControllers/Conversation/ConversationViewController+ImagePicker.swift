//
//  ConversationViewController+ImagePicker.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MobileCoreServices.UTType
import YepKit
import YepNetworking

extension ConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            switch mediaType {

            case String(kUTTypeImage):

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                    let fixedSize = image.yep_fixedSize

                    // resize to smaller, not need fixRotation

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: .High) {
                        sendImage(fixedImage)
                    }
                }

            case String(kUTTypeMovie):

                if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
                    println("videoURL \(videoURL)")
                    sendVideo(at: videoURL)
                }

            default:
                break
            }
        }

        dismiss(animated: true, completion: nil)
    }
}

