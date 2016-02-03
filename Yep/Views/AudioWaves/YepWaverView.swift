//
//  YepWaverView.swift
//  Yep
//
//  Created by kevinzhow on 15/4/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepWaverView: UIView {

    var waver: Waver!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        waver = Waver(frame: CGRectMake(0, CGRectGetHeight(self.bounds)/2.0 - 50.0 - 40.0, CGRectGetWidth(self.bounds), 100.0))
        self.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        self.addSubview(waver)
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        waver.removeFromSuperview()
    }
}

