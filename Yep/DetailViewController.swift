//
//  DetailViewController.swift
//  Yep
//
//  Created by ROC Zhang on 16/2/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var PolygonImageView: UIImageView!
    
    enum requestDetailFrom{
        case Conversation
        case Feeds
        case People
        case Skills
        case Meetup
    }
    
    private var conversation: Conversation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Dispose of any resources that can be recreated.
    }
    
    func initUI() {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appdelegate.detail = self
        self.view.backgroundColor = UIColor.yepViewBackgroundColor()
    }
    
    func requestHandle(date:AnyObject?,requestFrom:requestDetailFrom){
        switch requestFrom{
        case .Conversation:
            conversation = date as! Conversation
            performSegueWithIdentifier("showDetailConversation", sender: conversation)
        case .Feeds:
            performSegueWithIdentifier("showDetailFeedsOfProfileUser", sender: date)
        case .People:
            performSegueWithIdentifier("showDetailDiscover", sender: date)
        case .Skills:
            performSegueWithIdentifier("showDetailSkills", sender: date)
        case .Meetup:
            performSegueWithIdentifier("showDetailMeetup", sender: date)
        default:()
        }
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier{
            case "showDetailConversation":
                let vc = segue.destinationViewController as! ConversationViewController
                vc.conversation = conversation
            case "showDetailFeedsOfProfileUser":
                let vc = segue.destinationViewController as! FeedsViewController
                if let
                    info = (sender as? Box<[String: AnyObject]>)?.value,
                    profileUser = (info["profileUser"] as? Box<ProfileUser>)?.value,
                    feeds = (info["feeds"] as? Box<[DiscoveredFeed]>)?.value {
                        vc.profileUser = profileUser
                        vc.feeds = feeds
                        vc.preparedFeedsCount = feeds.count
                }
                vc.hideRightBarItem = true
                vc.hidesBottomBarWhenPushed = true
        default:()
            
        }
    }
    


}
