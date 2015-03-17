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

    @IBOutlet weak var registerButton: BorderButton!
    @IBOutlet weak var loginButton: BorderButton!

    @IBOutlet weak var companyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        logoLabel.text = NSLocalizedString("Yep", comment: "")
        sloganLabel.text = NSLocalizedString("Grow together", comment: "")

        registerButton.setTitle(NSLocalizedString("Sign Up", comment: ""), forState: .Normal)
        loginButton.setTitle(NSLocalizedString("Login", comment: ""), forState: .Normal)

        companyLabel.text = NSLocalizedString("Catch Inc.", comment: "")

        /*
        sendVerifyCode(ofMobile: "18602354812", withAreaCode: "86", failureHandler: nil) { success in
            if success {
                println("Verification code sent successfully")
            } else {
                println("Failed to send verification code")
            }
        }

        loginByMobile("18602354812", withAreaCode: "86", verifyCode: "4627", failureHandler: { (resource, reason, data) in
            defaultFailureHandler(forResource: resource, withFailureReason: reason, data)

            if let errorMessage = errorMessageInData(data) {
                println("errorMessage: \(errorMessage)")
            }

        }, completion: { loginUser in
            println("\(loginUser)")

            let accessToken = loginUser.accessToken
            // TODO: after login
        })

        unreadMessages { result in
            println("unreadMessages result: \(result)")
        }
        */
    }

    // MARK: Actions

    @IBAction func register(sender: UIButton) {
        performSegueWithIdentifier("showRegisterPickName", sender: nil)
    }

    @IBAction func login(sender: UIButton) {
        performSegueWithIdentifier("showLoginByMobile", sender: nil)
    }
}
