
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

    fileprivate lazy var disposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet fileprivate weak var openCameraButton: BorderButton!

    fileprivate lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.isEnabled = false
        button.rx_tap
            .subscribeNext({ [weak self] in self?.uploadAvatarAndGotoPickSkills() })
            .addDisposableTo(self.disposeBag)
        return button
    }()

    fileprivate var avatar = UIImage() {
        willSet {
            avatarImageView.image = newValue
        }
    }

    fileprivate enum PickAvatarState {
        case `default`
        case captured
    }

    fileprivate var pickAvatarState: PickAvatarState = .default {
        willSet {
            switch newValue {
            case .default:

                cameraPreviewView.isHidden = true
                avatarImageView.isHidden = false
                avatarImageView.image = UIImage.yep_defaultAvatar
                nextButton.isEnabled = false
                
            case .captured:
                cameraPreviewView.isHidden = true
                avatarImageView.isHidden = false

                nextButton.isEnabled = true
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
        
        view.backgroundColor = UIColor.white

        pickAvatarState = .default

        openCameraButton.setTitle(String.trans_buttonChooseFromLibrary, for: UIControlState())
        openCameraButton.setTitleColor(UIColor.white, for: UIControlState())
        openCameraButton.backgroundColor = UIColor.yepTintColor()
        openCameraButton.rx_tap
            .subscribeNext({ [weak self] in self?.openPhotoLibraryPicker() })
            .addDisposableTo(disposeBag)
    }

    // MARK: Actions

    fileprivate func openPhotoLibraryPicker() {
        
        let openCameraRoll: ProposerAction = { [weak self] in
            
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                self?.alertCanNotAccessCameraRoll()
                return
            }
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            self?.present(imagePicker, animated: true, completion: nil)
        }
        
        proposeToAccess(.Photos, agreed: openCameraRoll, rejected: { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        })
    }
    
    fileprivate func uploadAvatarAndGotoPickSkills() {
        
        YepHUD.showActivityIndicator()

        let image = avatar.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())

        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality)

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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {

        SafeDispatch.async { [weak self] in
            self?.avatar = image
            self?.pickAvatarState = .Captured
        }

        dismiss(animated: true, completion: nil)
    }
}

