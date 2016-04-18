//
//  ObjectKeypathObserver.swift
//  Yep
//
//  Created by NIX on 16/4/18.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ObjectKeypathObserver: NSObject {

    weak var object: NSObject?
    var keypath: String

    deinit {
        object?.removeObserver(self, forKeyPath: keypath)
    }

    init(object: NSObject, keypath: String) {

        self.object = object
        self.keypath = keypath

        super.init()

        object.addObserver(self, forKeyPath: keypath, options: [.New], context: nil)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        guard let object = object as? NSObject else {
            return
        }

        if object == self.object && keypath == self.keypath {

        }
    }
}
