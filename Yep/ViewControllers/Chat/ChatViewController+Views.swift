//
//  ChatViewController+Views.swift
//  Yep
//
//  Created by NIX on 16/7/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Proposer

// MARK: - MoreMessageTypesView

extension ChatViewController {

    func makeMoreMessageTypesView() -> MoreMessageTypesView {

        let view = MoreMessageTypesView()

        view.alertCanNotAccessCameraRollAction = { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        }

        view.sendImageAction = { [weak self] image in
            self?.send(image: image)
        }

        view.takePhotoAction = { [weak self] in

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .Camera
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Camera, agreed: openCamera, rejected: {
                self?.alertCanNotOpenCamera()
            })
        }

        view.choosePhotoAction = { [weak self] in

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .PhotoLibrary

                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                self?.alertCanNotAccessCameraRoll()
            })
        }

        view.pickLocationAction = { [weak self] in
            self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }
        
        return view
    }
}

