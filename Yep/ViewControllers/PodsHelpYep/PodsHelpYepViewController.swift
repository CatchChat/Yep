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

        var url: URL? {
            return URL(string: urlString)
        }
    }

    fileprivate let frameworks: [Framework] = [
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
            name: "DeviceUtil",
            urlString: "https://github.com/InderKumarRathore/DeviceUtil"
        ),
        Framework(
            name: "FayeClient",
            urlString: "https://github.com/nixzhu/FayeClient"
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
            name: "Realm",
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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleOpenSource

        tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    enum Section: Int {
        case yep
        case frameworks

        var headerTitle: String {
            switch self {
            case .yep:
                return NSLocalizedString("Yep", comment: "")
            case .frameworks:
                return NSLocalizedString("Third Party", comment: "")
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {
        case .yep:
            return 1
        case .frameworks:
            return frameworks.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        return section.headerTitle
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .yep:
            let cell = tableView.dequeueReusableCell(withIdentifier: "YepCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Yep on GitHub", comment: "")
            cell.detailTextLabel?.text = NSLocalizedString("Welcome contributions!", comment: "")
            return cell

        case .frameworks:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PodCell", for: indexPath)
            let framework = frameworks[indexPath.row]
            cell.textLabel?.text = framework.name
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .yep:
            return 60
        case .frameworks:
            return 44
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .yep:
            if let URL = URL(string: "https://github.com/CatchChat/Yep") {
                yep_openURL(URL)
            }

        case .frameworks:
            let framework = frameworks[indexPath.row]
            if let url = framework.url {
                yep_openURL(url)
            }
        }
    }
}

