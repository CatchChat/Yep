//
//  UserFeedsViewController.swift
//  Yep
//
//  Created by ChaiYixiao on 3/17/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class UserFeedsViewController: UIViewController {
    var feeds = [DiscoveredFeed]()
    var preparedFeedsCount = 0
    var profileUser: ProfileUser?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true

        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
