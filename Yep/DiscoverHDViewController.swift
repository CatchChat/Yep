//
//  DiscoverHDViewController.swift
//  Yep
//
//  Created by ROC Zhang on 16/2/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverHDViewController: UIViewController {

    @IBOutlet weak var DiscoverLeftTableView: UITableView!
    
    private var data = [
        DiscoverHDCellItemsGrounp(ItemIcon:"icon_feeds_active",ItemLabel:"Feeds"),
        DiscoverHDCellItemsGrounp(ItemIcon:"icon_minicard",ItemLabel:"People"),
        DiscoverHDCellItemsGrounp(ItemIcon:"icon_skills",ItemLabel:"Skills"),
        DiscoverHDCellItemsGrounp(ItemIcon:"icon_meetup",ItemLabel:"Meetup")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        DiscoverLeftTableView.dataSource = self
        DiscoverLeftTableView.delegate = self
        DiscoverLeftTableView.backgroundColor = UIColor.yepBackgroundColor()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DiscoverHDViewController:UITableViewDataSource,UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = DiscoverLeftTableView.dequeueReusableCellWithIdentifier("DiscoverLeftCell", forIndexPath: indexPath) as! DiscoverHDCell
        let groupInfo = data[indexPath.row]
        cell.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
        cell.ItemBackgroundImage.image = UIImage(named: "table_bg")
        cell.ItemIcon.image = UIImage(named: groupInfo.ItemIcon)
        cell.ItemLabel.text = groupInfo.ItemLabel
        cell.ItemLabel.textColor = UIColor.yepGrayColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
   
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.reloadData()
        
        let cell = DiscoverLeftTableView.cellForRowAtIndexPath(indexPath) as! DiscoverHDCell
        cell.ItemBackgroundImage.image = UIImage(named: "table_bg_active")
        
        if let detailNav = splitViewController?.childViewControllers[1] as? YepNavigationController{

            switch(indexPath.row){
                
            case 0:
                let feedsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FeedsViewController") as! FeedsViewController
                detailNav.replaceTopViewController(feedsVC)

            case 1:
                let usersVC = UIStoryboard(name: "DiscoverHD", bundle: nil).instantiateViewControllerWithIdentifier("DiscoverViewController") as! DiscoverViewController
                detailNav.replaceTopViewController(usersVC)
                
            case 2:
                break
//                (UIApplication.sharedApplication().delegate as! AppDelegate).detail.requestHandle(nil, requestFrom: DetailViewController.requestDetailFrom.Skills)
            case 3:
                break
//                (UIApplication.sharedApplication().delegate as! AppDelegate).detail.requestHandle(nil, requestFrom: DetailViewController.requestDetailFrom.Meetup)
            default:()
            }
        }
        
    }
    
}
