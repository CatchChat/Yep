//
//  ShowStepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShowStepViewController: UIViewController {

    var showName: String?

    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadHTML()
    }

    private func loadHTML() {

        if let htmlName = showName {
            if let
                htmlPath = NSBundle.mainBundle().pathForResource(htmlName, ofType: "html", inDirectory: "ShowResources"),
                string = String(contentsOfFile: htmlPath, encoding: NSUTF8StringEncoding, error: nil),
                baseURL = NSURL(fileURLWithPath: htmlPath) {

                    webView.loadHTMLString(string, baseURL: baseURL)
            }
        }
    }
}
