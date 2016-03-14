//
//  PopoverContentViewController.swift
//  Yep
//
//  Created by Bigbig Chai on 3/4/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class PopoverContentViewController: UIViewController {

//    weak var moreView: ConversationMoreViewManager.moreView?
    weak var moreViewManager:ConversationMoreViewManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
//        moreView.showInView(view)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
