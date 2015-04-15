//
//  RegisterSelectSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterSelectSkillsViewController: UIViewController {

    var annotationText: String = ""

    @IBOutlet weak var annotationLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        annotationLabel.text = annotationText

        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)
    }

    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
