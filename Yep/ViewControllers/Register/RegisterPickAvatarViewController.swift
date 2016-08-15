
//  RegisterPickAvatarViewController.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import YepKit
import YepNetworking
import Proposer
import Navi
import RxSwift
import RxCocoa

final class RegisterPickAvatarViewController: SegueViewController {

    private lazy var disposeBag = DisposeBag()
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet private weak var openCameraButton: BorderButton!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = NSLocalizedString("Next", comment: "")
        button.enabled = false
        button.rx_tap
            .subscribeNext({ [weak self] in self?.uploadAvatarAndGotoPickSkills() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    private var avatar = UIImage() {
        willSet {
            avatarImageView.image = newValue
        }
    }

    private enum PickAvatarState {
        case Default
        case Captured
    }

    private var pickAvatarState: PickAvatarState = .Default {
        willSet {
            switch newValue {
            case .Default:

                cameraPreviewView.hidden = true
                avatarImageView.hidden = false
                avatarImageView.image = UIImage.yep_defaultAvatar
                nextButton.enabled = false
                
            case .Captured:
                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                nextButton.enabled = true
            }
        }
    }

    deinit {
        println("deinit RegisterPickAvatar")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton
        
        navigationItem.hidesBackButton = true
        
        view.backgroundColor = UIColor.whiteColor()

        pickAvatarState = .Default

        openCameraButton.setTitle(String.trans_buttonChooseFromLibrary, forState: .Normal)
        openCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        openCameraButton.backgroundColor = UIColor.yepTintColor()
        openCameraButton.rx_tap
            .subscribeNext({ [weak self] in self?.openPhotoLibraryPicker() })
            .addDisposableTo(disposeBag)
    }

    // MARK: Actions

    private func openPhotoLibraryPicker() {
        
        let openCameraRoll: ProposerAction = { [weak self] in
            
            guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                self?.alertCanNotAccessCameraRoll()
                return
            }
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.allowsEditing = true
            
            self?.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        proposeToAccess(.Photos, agreed: openCameraRoll, rejected: { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        })
    }
    
    private func uploadAvatarAndGotoPickSkills() {
        
        YepHUD.showActivityIndicator()

        let image = avatar.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())

        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality())

        if let imageData = imageData {

            updateAvatarWithImageData(imageData, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepHUD.hideActivityIndicator()

            }, completion: { newAvatarURLString in
                YepHUD.hideActivityIndicator()

                SafeDispatch.async { [weak self] in

                    YepUserDefaults.avatarURLString.value = newAvatarURLString

                    self?.performSegueWithIdentifier("showRegisterPickSkills", sender: nil)
                }
            })
        }
    }
}

// MARK: UIImagePicker

extension RegisterPickAvatarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {

        SafeDispatch.async { [weak self] in
            self?.avatar = image
            self?.pickAvatarState = .Captured
        }

        dismissViewControllerAnimated(true, completion: nil)
    }
}

