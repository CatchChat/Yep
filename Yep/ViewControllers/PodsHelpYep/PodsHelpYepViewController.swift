//
//  PodsHelpYepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class PodsHelpYepViewController: UITableViewController {

    let pods: [[String: String]] = [
        [
            "name": "RealmSwift",
            "URLString": "https://realm.io",
        ],
        [
            "name": "MZFayeClient",
            "URLString": "https://github.com/m1entus/MZFayeClient",
        ],
        [
            "name": "Proposer",
            "URLString": "https://github.com/nixzhu/Proposer",
        ],
        [
            "name": "KeyboardMan",
            "URLString": "https://github.com/nixzhu/KeyboardMan",
        ],
        [
            "name": "Ruler",
            "URLString": "https://github.com/nixzhu/Ruler",
        ],
        [
            "name": "MonkeyKing",
            "URLString": "https://github.com/nixzhu/MonkeyKing",
        ],
        [
            "name": "APAddressBook/Swift",
            "URLString": "https://github.com/Alterplay/APAddressBook",
        ],
        [
            "name": "1PasswordExtension",
            "URLString": "https://github.com/AgileBits/onepassword-app-extension",
        ],
        [
            "name": "Kingfisher",
            "URLString": "https://github.com/onevcat/Kingfisher",
        ],
        [
            "name": "FXBlurView",
            "URLString": "https://github.com/nicklockwood/FXBlurView",
        ],
        [
            "name": "TPKeyboardAvoiding",
            "URLString": "https://github.com/michaeltyson/TPKeyboardAvoidin",
        ],
        [
            "name": "DeviceGuru",
            "URLString": "https://github.com/InderKumarRathore/DeviceGuru",
        ],
        [
            "name": "AFNetworking",
            "URLString": "https://github.com/AFNetworking/AFNetworkin",
        ],
        [
            "name": "pop",
            "URLString": "https://github.com/facebook/pop",
        ],
    ].sorted({ a, b in
        if let
            nameA = a["name"],
            nameB = b["name"] {

                return nameA < nameB
        }

        return true
    })

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Pods", comment: "")

        tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pods.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PodCell", forIndexPath: indexPath) as! UITableViewCell

        let pod = pods[indexPath.row]

        cell.textLabel?.text = pod["name"]

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let pod = pods[indexPath.row]

        if let
            URLString = pod["URLString"],
            URL = NSURL(string: URLString) {
                UIApplication.sharedApplication().openURL(URL)
        }
    }
}

