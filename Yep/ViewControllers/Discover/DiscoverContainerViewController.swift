//
//  DiscoverContainerViewController.swift
//  Yep
//
//  Created by NIX on 16/5/26.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverContainerViewController: UIViewController {

    enum Option: Int {
        case MeetGenius
        case FindAll

        var title: String {
            switch self {
            case .MeetGenius:
                return NSLocalizedString("Meet Genius", comment: "")
            case .FindAll:
                return NSLocalizedString("Find All", comment: "")
            }
        }
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.removeAllSegments()
            (0..<2).forEach({
                let option = Option(rawValue: $0)
                segmentedControl.insertSegmentWithTitle(option?.title, atIndex: $0, animated: false)
            })
        }
    }

    @IBOutlet weak var geniusesContainerView: UIView!
    @IBOutlet weak var discoveredUsersContainerView: UIView!

    var currentOption: Option = .MeetGenius {
        didSet {
            switch currentOption {

            case .MeetGenius:
                geniusesContainerView.hidden = false
                discoveredUsersContainerView.hidden = true

            case .FindAll:
                geniusesContainerView.hidden = true
                discoveredUsersContainerView.hidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        currentOption = .MeetGenius

        segmentedControl.selectedSegmentIndex = currentOption.rawValue
        segmentedControl.addTarget(self, action: #selector(DiscoverContainerViewController.chooseOption(_:)), forControlEvents: .ValueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func chooseOption(sender: UISegmentedControl) {

        guard let option = Option(rawValue: sender.selectedSegmentIndex) else {
            return
        }

        currentOption = option
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
