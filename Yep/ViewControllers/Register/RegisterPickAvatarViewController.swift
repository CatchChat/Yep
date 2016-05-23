
//  RegisterPickAvatarViewController.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import YepKit
import YepConfig
import YepNetworking
import Proposer
import Navi

final class RegisterPickAvatarViewController: SegueViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet private weak var openCameraButton: BorderButton!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: #selector(RegisterPickAvatarViewController.next(_:)))
            button.enabled = false
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
                avatarImageView.image = UIImage(named: "default_avatar")
                nextButton.enabled = false
                
            case .Captured:
                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                nextButton.enabled = true
            }
        }
    }

    private lazy var sessionQueue: dispatch_queue_t = dispatch_queue_create("session_queue", DISPATCH_QUEUE_SERIAL)

    private lazy var session: AVCaptureSession = {
        let _session = AVCaptureSession()
        _session.sessionPreset = AVCaptureSessionPreset640x480

        return _session
    }()

    private let mediaType = AVMediaTypeVideo

    private lazy var videoDeviceInput: AVCaptureDeviceInput? = {
        guard let videoDevice = self.deviceWithMediaType(self.mediaType, preferringPosition: .Front) else {
            return nil
        }

        return try? AVCaptureDeviceInput(device: videoDevice)
    }()

    private lazy var stillImageOutput: AVCaptureStillImageOutput = {
        let _stillImageOutput = AVCaptureStillImageOutput()
        _stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        return _stillImageOutput
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))

        navigationItem.rightBarButtonItem = nextButton
        
        navigationItem.hidesBackButton = true
        
        view.backgroundColor = UIColor.whiteColor()

        pickAvatarState = .Default

        openCameraButton.setTitle(NSLocalizedString("Choose from Library", comment: ""), forState: .Normal)
        openCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        openCameraButton.backgroundColor = UIColor.yepTintColor()
        openCameraButton.addTarget(self, action: #selector(RegisterPickAvatarViewController.openPhotoLibraryPicker), forControlEvents: .TouchUpInside)

    }
    
    // MARK: Helpers
    
    private func deviceWithMediaType(mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice = devices.first as? AVCaptureDevice
        for device in devices as! [AVCaptureDevice] {
            if device.position == position {
                captureDevice = device
                break
            }
        }

        return captureDevice
    }

    // MARK: Actions

    @objc private func next(sender: UIBarButtonItem) {
        uploadAvatarAndGotoPickSkills()
    }

    @objc private func openPhotoLibraryPicker() {
        
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
        
        proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
            self.alertCanNotAccessCameraRoll()
        })
    }
    
    private func uploadAvatarAndGotoPickSkills() {
        
        YepHUD.showActivityIndicator()

        let image = avatar.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())

        let imageData = UIImageJPEGRepresentation(image, YepConfig.avatarCompressionQuality())

        if let imageData = imageData {

            updateAvatarWithImageData(imageData, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                YepHUD.hideActivityIndicator()

            }, completion: { newAvatarURLString in
                YepHUD.hideActivityIndicator()

                dispatch_async(dispatch_get_main_queue()) {

                    YepUserDefaults.avatarURLString.value = newAvatarURLString

                    self.performSegueWithIdentifier("showRegisterPickSkills", sender: nil)
                }
            })
        }
    }

}

// MARK: UIImagePicker

extension RegisterPickAvatarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {

        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.avatar = image
            self?.pickAvatarState = .Captured
        }

        dismissViewControllerAnimated(true, completion: nil)
    }
}

