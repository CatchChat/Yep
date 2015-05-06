//
//  SkillHomeViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillHomeViewController: UIViewController {
    
    var skillName: String? {
        didSet {
            self.title = skillName
        }
    }
    
    @IBOutlet weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    var discoveredMasterUsers = [DiscoveredUser]()
    
    var discoveredLearningUsers = [DiscoveredUser]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let skillNameString = skillName {
            discoverUserBySkillName(skillNameString)
        }
        
        self.headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight
        
        customTitleView()

        // Do any additional setup after loading the view.
    }
    
    func customTitleView() {
        
        var titleLabel = UILabel()
        
        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]
        
        var titleAttr = NSMutableAttributedString(string: skillName!, attributes:textAttributes)
        
        titleLabel.attributedText = titleAttr
        
        titleLabel.textAlignment = NSTextAlignment.Center
        
        titleLabel.backgroundColor = UIColor.yepTintColor()
        
        titleLabel.sizeToFit()
        
        titleLabel.bounds = CGRectInset(titleLabel.frame, -25.0, -4.0)
        
        titleLabel.layer.cornerRadius = titleLabel.frame.size.height/2.0
        
        titleLabel.layer.masksToBounds = true
        
        self.navigationItem.titleView = titleLabel
    }
    
    func discoverUserBySkillName(skillName: String) {
        
        discoverUsers(masterSkills: [skillName], learningSkills: [], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            
            }, completion: { discoveredUsers in
                self.discoveredMasterUsers = discoveredUsers
                
                dispatch_async(dispatch_get_main_queue()) {
                }
        })
        
        discoverUsers(masterSkills: [], learningSkills: [skillName], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            
            }, completion: { discoveredUsers in
                self.discoveredLearningUsers = discoveredUsers
                
                dispatch_async(dispatch_get_main_queue()) {
                }
        })
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


