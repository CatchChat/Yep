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
        case SocialWork
    }
    
    
    private var conversation: Conversation!
    
    var profileUser: ProfileUser?
    var dribbbleWork: DribbbleWork?
    var instagramWork: InstagramWork?
    var githubWork: GithubWork?

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
        case .SocialWork:
            let dic = date as! [String]
            let segueID = dic[0].substringFromIndex(dic[0].startIndex.advancedBy(4))
            performSegueWithIdentifier("showDetail\(segueID)", sender: dic[1])
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
//                vc.hideRightBarItem = true
                vc.hidesBottomBarWhenPushed = true
            
            case "showDetailSocialWorkGithub":
                if let providerName = sender as? String {
                    
                    let vc = segue.destinationViewController as! SocialWorkGithubViewController
                    vc.socialAccount = SocialAccount(rawValue: providerName)
                    vc.profileUser = profileUser
                    vc.githubWork = githubWork
                    
                    vc.afterGetGithubWork = {[weak self] githubWork in
                        self?.githubWork = githubWork
                    }
            }
            
            case "showDetailSocialWorkDribbble":
                if let providerName = sender as? String {
                    
                    let vc = segue.destinationViewController as! SocialWorkDribbbleViewController
                    vc.socialAccount = SocialAccount(rawValue: providerName)
                    vc.profileUser = profileUser
                    vc.dribbbleWork = dribbbleWork
                    
                    vc.afterGetDribbbleWork = { [weak self] dribbbleWork in
                        self?.dribbbleWork = dribbbleWork
                    }
            }
            
            case "showDetailSocialWorkInstagram":
                if let providerName = sender as? String {
                    
                    let vc = segue.destinationViewController as! SocialWorkInstagramViewController
                    vc.socialAccount = SocialAccount(rawValue: providerName)
                    vc.profileUser = profileUser
                    vc.instagramWork = instagramWork
                    
                    vc.afterGetInstagramWork = { [weak self] instagramWork in
                        self?.instagramWork = instagramWork
                    }
            }
        default:()
            
        }
    }
    


}
