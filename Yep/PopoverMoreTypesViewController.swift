//
//  PopoverMoreTypesViewController.swift
//  Yep
//
//  Created by Bigbig Chai on 3/8/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit
import Photos

class PopoverMoreTypesViewController: UIViewController {

    @IBOutlet weak var moreTypesView: MoreMessageTypesView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        
        moreTypesView.showInView(view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
