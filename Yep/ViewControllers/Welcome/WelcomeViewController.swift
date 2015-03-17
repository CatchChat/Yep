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

        tryYepNetworking()

    }

    func tryYepNetworking() {

        let baseURL = NSURL(string: "http://park.catchchatchina.com/api/")!

        func verifyCode(ofMobile mobile: String, withAreaCode areaCode: String) -> Resource<[String: String]> {

            let requestParameters = [
                "mobile": mobile,
                "phone_code": areaCode,
            ]

            let parse: JSONDictionary -> [String: String]? = { data in
                return data as? [String: String]
            }

            return jsonResource("v1/auth/send_verify_code", .POST, requestParameters, parse)
        }

        apiRequest({_ in}, baseURL, verifyCode(ofMobile: "18602354812", withAreaCode: "86"), defaultFailureHandler) { result in
            println("result: \(result)")
        }
    }

    // MARK: Actions

    @IBAction func register(sender: UIButton) {
        performSegueWithIdentifier("showRegisterPickName", sender: nil)
    }

    @IBAction func login(sender: UIButton) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.startMainStory()
        }
    }
}
