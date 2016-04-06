//
//  SearchedUserMessagesViewController.swift
//  Yep
//
//  Created by NIX on 16/4/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUserMessagesViewController: UIViewController {

    private let searchedMessageCellID = "SearchedMessageCell"

    @IBOutlet weak var messagesTableView: UITableView! {
        didSet {
            messagesTableView.separatorColor = UIColor.yepCellSeparatorColor()
            messagesTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            messagesTableView.registerNib(UINib(nibName: searchedMessageCellID, bundle: nil), forCellReuseIdentifier: searchedMessageCellID)

            messagesTableView.rowHeight = 80

            messagesTableView.tableFooterView = UIView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
