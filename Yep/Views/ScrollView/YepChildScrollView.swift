//
//  YepChildScrollView.swift
//  Yep
//
//  Created by kevinzhow on 15/5/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepChildScrollView: UITableView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return false
        
    }
}
