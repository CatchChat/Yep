//
//  UIImagePickerController+Yep.swift
//  Yep
//
//  Created by ChaiYixiao on 3/10/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

extension UIImagePickerController {
    
    override public func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        print("willAnimateRotationToInterfaceOrientation")
    }
    
    override public func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        print("didRotateFromInterfaceOrientation")
    }
    
    override public func shouldAutorotate() -> Bool {

        return true
    }
}