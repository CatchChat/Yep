//
//  RegisterPickAvatarViewController.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class RegisterPickAvatarViewController: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cameraPreviewView: CameraPreviewView!

    @IBOutlet weak var takePicturePromptLabel: UILabel!

    @IBOutlet weak var openCameraButton: BorderButton!

    @IBOutlet weak var cameraRollButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!

    lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .Plain, target: self, action: "next:")
        return button
        }()

    var avatar = UIImage() {
        willSet {
            avatarImageView.image = newValue
        }
    }

    enum PickAvatarState {
        case Default
        case CameraOpen
        case Captured
    }

    var pickAvatarState: PickAvatarState = .Default {
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

    lazy var sessionQueue = {
        return dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        }()

    lazy var session: AVCaptureSession = {
        let _session = AVCaptureSession()
        _session.sessionPreset = AVCaptureSessionPreset640x480

        return _session
        }()

    let mediaType = AVMediaTypeVideo

    lazy var videoDeviceInput: AVCaptureDeviceInput = {
        var error: NSError? = nil
        let videoDevice = self.deviceWithMediaType(self.mediaType, preferringPosition: .Front)
        return AVCaptureDeviceInput(device: videoDevice!, error: &error)
        }()

    lazy var stillImageOutput: AVCaptureStillImageOutput = {
        let _stillImageOutput = AVCaptureStillImageOutput()
        _stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        return _stillImageOutput
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Avatar", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        view.backgroundColor = UIColor.whiteColor()

        pickAvatarState = .Default

        takePicturePromptLabel.textColor = UIColor.blackColor()
        takePicturePromptLabel.text = NSLocalizedString("Set an avatar", comment: "")

        openCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        openCameraButton.backgroundColor = UIColor.yepTintColor()
        
        cameraRollButton.tintColor = UIColor.yepTintColor()
        captureButton.tintColor = UIColor.yepTintColor()
        retakeButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

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

    func next(sender: UIBarButtonItem) {
        uploadAvatarAndGotoPickSkills()
    }

    @IBAction func tryOpenCamera(sender: UIButton) {

        AVCaptureDevice.requestAccessForMediaType(mediaType, completionHandler: { (granted) -> Void in
            if granted {
                self.openCamera()

            } else {
                self.alertCanNotOpenCamera()
            }
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

    @IBAction func tryOpenCameraRoll(sender: UIButton) {

        let openCameraRoll: () -> Void = { [weak self] in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
                imagePicker.allowsEditing = false

                self?.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }

        PHPhotoLibrary.requestAuthorization { status in

            switch status {

            case .Authorized:
                openCameraRoll()

            default:
                self.alertCanNotAccessCameraRoll()
            }
        }
    }

    func uploadAvatarAndGotoPickSkills() {
        
        YepHUD.showActivityIndicator()

        avatar = self.avatar.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())
        let imageData = UIImageJPEGRepresentation(avatar, YepConfig.avatarCompressionQuality())

        s3PublicUploadFile(inFilePath: nil, orFileData: imageData, mimeType: "image/jpeg", failureHandler: { (reason, errorMessage) in

            defaultFailureHandler(reason, errorMessage)

            YepHUD.hideActivityIndicator()

        }, completion: { s3UploadParams in

            let newAvatarURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

            updateMyselfWithInfo(["avatar_url": newAvatarURLString], failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason, errorMessage)

                YepHUD.hideActivityIndicator()

            }, completion: { success in

                YepHUD.hideActivityIndicator()

                dispatch_async(dispatch_get_main_queue()) {

                    YepUserDefaults.avatarURLString.value = newAvatarURLString

                    self.performSegueWithIdentifier("showRegisterPickSkills", sender: nil)
                }
            })
        })
    }

    @IBAction func captureOrFinish(sender: UIButton) {
        if pickAvatarState == .Captured {
            uploadAvatarAndGotoPickSkills()

        } else {
            dispatch_async(sessionQueue) {
                self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(self.mediaType), completionHandler: { (imageDataSampleBuffer, error) -> Void in
                    if error == nil {
                        let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                        var image = UIImage(data: data)!

                        image = UIImage(CGImage: image.CGImage, scale: image.scale, orientation: .LeftMirrored)!

                        image = image.fixRotation().largestCenteredSquareImage()

                        dispatch_async(dispatch_get_main_queue()) {
                            self.avatar = image
                            self.pickAvatarState = .Captured
                        }
                    }
                })
            }
        }
    }

    @IBAction func retake(sender: UIButton) {
        pickAvatarState = .CameraOpen
    }

}

// MARK: UIImagePicker

extension RegisterPickAvatarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.avatar = image
            self.pickAvatarState = .Captured
        }

        dismissViewControllerAnimated(true, completion: nil)
    }
}
