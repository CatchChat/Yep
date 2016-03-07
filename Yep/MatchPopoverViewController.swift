//
//  MatchPopoverViewController.swift
//  Yep
//
//  Created by Bigbig Chai on 3/6/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class MatchPopoverViewController: UIViewController {

    @IBOutlet weak var filterView: DiscoverFilterView!

    override func viewDidLoad() {
        super.viewDidLoad()

        print("filterView___\(filterView),view.frame_____\(view.frame)")
        filterView.showInView(view)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
