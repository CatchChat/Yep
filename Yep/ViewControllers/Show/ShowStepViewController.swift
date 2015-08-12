//
//  ShowStepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.hidden = true
    }

}
