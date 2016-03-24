//
//  RegisterPickAvatarViewController.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Proposer
import Navi

class RegisterPickAvatarViewController: SegueViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet private weak var takePicturePromptLabel: UILabel!

    @IBOutlet private weak var openCameraButton: BorderButton!

    @IBOutlet private weak var cameraRollButton: UIButton!
    @IBOutlet private weak var captureButton: UIButton!
    @IBOutlet private weak var retakeButton: UIButton!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
    }()

    private var avatar = UIImage() {
        willSet {
            avatarImageView.image = newValue
        }
    }

    private enum PickAvatarState {
        case Default
        case CameraOpen
        case Captured
    }

    private var pickAvatarState: PickAvatarState = .Default {
        willSet {
            switch newValue {
            case .Default:
                openCameraButton.hidden = false

                cameraRollButton.hidden = true
                captureButton.hidden = true
                retakeButton.hidden = true

                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                avatarImageView.image = UIImage(named: "default_avatar")

                nextButton.enabled = false

            case .CameraOpen:
                openCameraButton.hidden = true

                cameraRollButton.hidden = false
                captureButton.hidden = false
                retakeButton.hidden = true

                cameraPreviewView.hidden = false
                avatarImageView.hidden = false

                captureButton.setImage(UIImage(named: "button_capture"), forState: .Normal)

                nextButton.enabled = false

            case .Captured:
                openCameraButton.hidden = true

                cameraRollButton.hidden = false
                captureButton.hidden = false
                retakeButton.hidden = false

                cameraPreviewView.hidden = true
                avatarImageView.hidden = false

                captureButton.setImage(UIImage(named: "button_capture_ok"), forState: .Normal)

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

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Avatar", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        view.backgroundColor = UIColor.whiteColor()

        pickAvatarState = .Default

        takePicturePromptLabel.textColor = UIColor.blackColor()
        takePicturePromptLabel.text = NSLocalizedString("Set an avatar", comment: "")

        openCameraButton.setTitle(NSLocalizedString("Open Camera", comment: ""), forState: .Normal)
        openCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        openCameraButton.backgroundColor = UIColor.yepTintColor()
        
        cameraRollButton.tintColor = UIColor.yepTintColor()
        captureButton.tintColor = UIColor.yepTintColor()
        retakeButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)

        nextButton.enabled = false
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

    @IBAction private func tryOpenCamera(sender: UIButton) {
        proposeToAccess(.Camera, agreed: {
            self.openCamera()

        }, rejected: {
            self.alertCanNotOpenCamera()
        })
    }

    private func openCamera() {

        dispatch_async(dispatch_get_main_queue()) {
            self.pickAvatarState = .CameraOpen
        }

        dispatch_async(sessionQueue) {

            if self.session.canAddInput(self.videoDeviceInput) {
                self.session.addInput(self.videoDeviceInput)

                dispatch_async(dispatch_get_main_queue()) {

                    self.cameraPreviewView.session = self.session
                    let orientation = AVCaptureVideoOrientation(rawValue: UIInterfaceOrientation.Portrait.rawValue)!
                    (self.cameraPreviewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                }
            }

            if self.session.canAddOutput(self.stillImageOutput){
                self.session.addOutput(self.stillImageOutput)
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.session.startRunning()
            }
        }
    }

    @IBAction private func tryOpenCameraRoll(sender: UIButton) {

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

    @IBAction private func captureOrFinish(sender: UIButton) {
        if pickAvatarState == .Captured {
            uploadAvatarAndGotoPickSkills()

        } else {
            dispatch_async(sessionQueue) { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                guard let captureConnection = strongSelf.stillImageOutput.connectionWithMediaType(strongSelf.mediaType) else {
                    return
                }

                strongSelf.stillImageOutput.captureStillImageAsynchronouslyFromConnection(captureConnection, completionHandler: { imageDataSampleBuffer, error in
                    if error == nil {
                        let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                        var image = UIImage(data: data)!

                        if let CGImage = image.CGImage {
                            image = UIImage(CGImage: CGImage, scale: image.scale, orientation: .LeftMirrored)
                        }

                        image = image.fixRotation().navi_centerCropWithSize(YepConfig.avatarMaxSize())!

                        dispatch_async(dispatch_get_main_queue()) { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }

                            strongSelf.avatar = image
                            strongSelf.pickAvatarState = .Captured
                        }
                    }
                })
            }
        }
    }

    @IBAction private func retake(sender: UIButton) {
        pickAvatarState = .CameraOpen
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

