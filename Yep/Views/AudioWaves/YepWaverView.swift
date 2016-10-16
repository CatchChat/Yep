//
//  YepWaverView.swift
//  Yep
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class YepWaverView: UIView {

    var waver: Waver!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        waver = Waver(frame: CGRect(x: 0, y: self.bounds.height/2.0 - 50.0 - 40.0, width: self.bounds.width, height: 100.0))
        self.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.addSubview(waver)
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        waver.removeFromSuperview()
    }
}

