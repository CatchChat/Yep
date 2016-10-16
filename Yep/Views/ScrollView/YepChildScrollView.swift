//
//  YepChildScrollView.swift
//  Yep
//
//  Created by kevinzhow on 15/5/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class YepChildScrollView: UITableView {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return false
    }
}

