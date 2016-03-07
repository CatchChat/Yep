//
//  PopoverContentViewController.swift
//  Yep
//
//  Created by Bigbig Chai on 3/4/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class PopoverContentViewController: UIViewController {

    var conversationMoreView = ConversationMoreView() {
        didSet {
            setupConversationMoreView()
        }
    }
    var moreMessageTypeView = MoreMessageTypesView() {
        didSet {
            setupMoreMessageTypeView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setupConversationMoreView() {
        conversationMoreView.showInView(view)
    }

    func setupMoreMessageTypeView() {
        moreMessageTypeView.showInView(view)
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
