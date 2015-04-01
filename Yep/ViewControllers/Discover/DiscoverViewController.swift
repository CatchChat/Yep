//
//  DiscoverViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverViewController: UIViewController {

    @IBOutlet weak var discoverTableView: UITableView!
    
    let cellIdentifier = "ContactsCell"
    
    var users = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.whiteColor()
        
        discoverTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        discoverTableView.rowHeight = 80
        
        discoverTableView.dataSource = self
        
        discoverTableView.delegate = self
        
        discoverUsers(master_skills: ["ruby"], learning_skills: ["singing"], sort: "last_sign_in_at", failureHandler: { (reason, error) in
            
        }, completion: { data in

            self.users = data["users"] as! [AnyObject]
            
            println("\(self.users)")
            
            self.reloadDiscoverData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadDiscoverData() {
        dispatch_async(dispatch_get_main_queue(),{
            self.discoverTableView.reloadData()
        });
        
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

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(users.count)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        
        let user = users[indexPath.row] as! NSDictionary
        
        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
        
        if let avatarURLString = user.valueForKey("avatar_url") as? String {
            AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    cell.avatarImageView.image = roundImage
                }
            }
        }

        cell.nameLabel.text = user.valueForKey("nickname") as? String
        cell.joinedDateLabel.text = user.valueForKey("last_sign_in_at") as? String
        cell.lastTimeSeenLabel.text = user.valueForKey("last_sign_in_at") as? String
        return cell
    }
}