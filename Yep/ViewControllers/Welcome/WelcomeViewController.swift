//
//  WelcomeViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var sloganLabel: UILabel!

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var companyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        logoLabel.text = NSLocalizedString("Yep", comment: "")
        sloganLabel.text = NSLocalizedString("Grow together", comment: "")

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), forState: .Normal)
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), forState: .Normal)

        companyLabel.text = NSLocalizedString("Catch Inc.", comment: "")


        registerButton.layer.cornerRadius = 6
        registerButton.layer.borderColor = UIColor.yepTintColor().CGColor
        registerButton.layer.borderWidth = 1.0

        loginButton.layer.cornerRadius = 6
        loginButton.layer.borderColor = UIColor.yepTintColor().CGColor
        loginButton.layer.borderWidth = 1.0
    }

    // MARK: Actions

    @IBAction func register(sender: UIButton) {
        performSegueWithIdentifier("showRegisterPickName", sender: nil)
    }

    @IBAction func login(sender: UIButton) {
    }
}
