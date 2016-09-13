//
//  PodsHelpYepViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class PodsHelpYepViewController: UITableViewController {

    struct Framework {
        let name: String
        let urlString: String
    }

    private let frameworks: [Framework] = [
        Framework(
            name: "Alamofire",
            urlString: "https://github.com/Alamofire/Alamofire"
        ),
        Framework(
            name: "AudioBot",
            urlString: "https://github.com/nixzhu/AudioBot"
        ),
        Framework(
            name: "AutoReview",
            urlString: "https://github.com/nixzhu/AutoReview"
        ),
        Framework(
            name: "DeviceGuru",
            urlString: "https://github.com/InderKumarRathore/DeviceGuru"
        ),
        Framework(
            name: "FXBlurView",
            urlString: "https://github.com/nicklockwood/FXBlurView"
        ),
        Framework(
            name: "KeyboardMan",
            urlString: "https://github.com/nixzhu/KeyboardMan"
        ),
        Framework(
            name: "KeypathObserver",
            urlString: "https://github.com/nixzhu/KeypathObserver"
        ),
        Framework(
            name: "Kingfisher",
            urlString: "https://github.com/onevcat/Kingfisher"
        ),
        Framework(
            name: "MonkeyKing",
            urlString: "https://github.com/nixzhu/MonkeyKing"
        ),
        Framework(
            name: "Navi",
            urlString: "https://github.com/nixzhu/Navi"
        ),
        Framework(
            name: "Pop",
            urlString: "https://github.com/facebook/pop"
        ),
        Framework(
            name: "Proposer",
            urlString: "https://github.com/nixzhu/Proposer"
        ),
        Framework(
            name: "ReSwift",
            urlString: "https://github.com/ReSwift/ReSwift"
        ),
        Framework(
            name: "RealmSwift",
            urlString: "https://github.com/realm/realm-cocoa"
        ),
        Framework(
            name: "Ruler",
            urlString: "https://github.com/nixzhu/Ruler"
        ),
        Framework(
            name: "RxSwift",
            urlString: "https://github.com/ReactiveX/RxSwift"
        ),
        Framework(
            name: "TPKeyboardAvoiding",
            urlString: "https://github.com/michaeltyson/TPKeyboardAvoiding"
        ),
    ]
    
    private let pods: [[String: String]] = [
        [
            "name": "RealmSwift",
            "URLString": "https://github.com/realm/realm-cocoa",
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
            "name": "Navi",
            "URLString": "https://github.com/nixzhu/Navi",
        ],
        [
            "name": "AudioBot",
            "URLString": "https://github.com/nixzhu/AudioBot",
        ],
        [
            "name": "AutoReview",
            "URLString": "https://github.com/nixzhu/AutoReview",
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
            "URLString": "https://github.com/michaeltyson/TPKeyboardAvoiding",
        ],
        [
            "name": "DeviceGuru",
            "URLString": "https://github.com/InderKumarRathore/DeviceGuru",
        ],
        [
            "name": "Alamofire",
            "URLString": "https://github.com/Alamofire/Alamofire",
        ],
        [
            "name": "Pop",
            "URLString": "https://github.com/facebook/pop",
        ],
        [
            "name": "RxSwift",
            "URLString": "https://github.com/ReactiveX/RxSwift",
        ],
        [
            "name": "ReSwift",
            "URLString": "https://github.com/ReSwift/ReSwift",
        ],
        [
            "name": "KeypathObserver",
            "URLString": "https://github.com/nixzhu/KeypathObserver",
        ],

    ].sort({ a, b in
        if let nameA = a["name"], nameB = b["name"] {
            return nameA < nameB
        }

        return true
    })

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleOpenSource

        tableView.tableFooterView = UIView()

        pods.forEach({ pod in
            print("Framework(\n\tname: \"\(pod["name"]!)\",\n\turlString: \"\(pod["URLString"]!)\"\n),")
        })
    }

    // MARK: - Table view data source

    enum Section: Int {
        case Yep
        case Pods

        var headerTitle: String {
            switch self {
            case .Yep:
                return NSLocalizedString("Yep", comment: "")
            case .Pods:
                return NSLocalizedString("Third Party", comment: "")
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {
        case .Yep:
            return 1
        case .Pods:
            return pods.count
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        return section.headerTitle
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Yep:
            let cell = tableView.dequeueReusableCellWithIdentifier("YepCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Yep on GitHub", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("Welcome contributions!", comment: "")
            return cell

        case .Pods:
            let cell = tableView.dequeueReusableCellWithIdentifier("PodCell", forIndexPath: indexPath)
            let pod = pods[indexPath.row]
            cell.textLabel?.text = pod["name"]
            return cell
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .Yep:
            return 60
        case .Pods:
            return 44
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Yep:
            if let URL = NSURL(string: "https://github.com/CatchChat/Yep") {
                yep_openURL(URL)
            }

        case .Pods:
            let pod = pods[indexPath.row]
            if let URLString = pod["URLString"], URL = NSURL(string: URLString) {
                yep_openURL(URL)
            }
        }
    }
}

