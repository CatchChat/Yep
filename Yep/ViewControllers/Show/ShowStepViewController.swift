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

    typealias FinishAction = () -> Void
    var finishAction: FinishAction?

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var finishButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadHTML()

        if let _ = finishAction {
            finishButton.setTitle(NSLocalizedString("Start, Yep", comment: ""), forState: .Normal)
            finishButton.hidden = false
            finishButton.addTarget(self, action: "finish", forControlEvents: .TouchUpInside)
        }
    }

    func finish() {
        finishAction?()
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
