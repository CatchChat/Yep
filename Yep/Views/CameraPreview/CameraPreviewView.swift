//
//  CameraPreviewView.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPreviewView: UIView {

    var session: AVCaptureSession? {
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set (session) {
            (self.layer as! AVCaptureVideoPreviewLayer).session = session
        }
    }

    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        (self.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
    }
}

