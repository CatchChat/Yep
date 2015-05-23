//
//  SkillHomeViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum SkillHomeState: Printable {
    case Master
    case Learning
    
    var description: String {
        switch self {
        case .Master:
            return "Master"
        case .Learning:
            return "Learning"
        }
    }
}

class SkillHomeViewController: CustomNavigationBarViewController {
    
    let cellIdentifier = "ContactsCell"
    
    lazy var masterTableView: UITableView = {
        
        var tempTableView = UITableView(frame: CGRectZero)

        
        return tempTableView;
        
    }()
    
    lazy var learningtTableView: UITableView = {
        
        var tempTableView = UITableView(frame: CGRectZero)
        
        
        return tempTableView;
        
    }()
    
    var skillName: String? {
        didSet {
            self.title = skillName
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    var isFirstAppear = true
    
    var state: SkillHomeState = .Master {
        willSet {
            
            switch newValue {
            case .Master:
                headerView.learningButton.setInActive()
                headerView.masterButton.setActive()
                skillHomeScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                
            case .Learning:
                headerView.masterButton.setInActive()
                headerView.learningButton.setActive()
                skillHomeScrollView.setContentOffset(CGPoint(x: masterTableView.frame.size.width, y: 0), animated: true)
   
            }
            
        }
    }
    
    @IBOutlet weak var skillHomeScrollView: UIScrollView!
    
    @IBOutlet weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    var discoveredMasterUsers = [DiscoveredUser]()
    
    var discoveredLearningUsers = [DiscoveredUser]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        masterTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        masterTableView.rowHeight = 80
        masterTableView.dataSource = self
        masterTableView.delegate = self
        masterTableView.tag = SkillHomeState.Master.hashValue
        
        
        learningtTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        learningtTableView.rowHeight = 80
        learningtTableView.dataSource = self
        learningtTableView.delegate = self
        learningtTableView.tag = SkillHomeState.Learning.hashValue

        if let skillNameString = skillName {
            discoverUserBySkillName(skillNameString)
        }
        
        self.headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight
        
        headerView.masterButton.addTarget(self, action: "changeToMaster", forControlEvents: UIControlEvents.TouchUpInside)
        headerView.learningButton.addTarget(self, action: "changeToLearning", forControlEvents: UIControlEvents.TouchUpInside)
        
        skillHomeScrollView.addSubview(masterTableView)
        skillHomeScrollView.addSubview(learningtTableView)
        skillHomeScrollView.pagingEnabled = true
        skillHomeScrollView.delegate = self
        skillHomeScrollView.bounces = false
        
        customTitleView()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        let height = YepConfig.getScreenRect().height - headerView.frame.height
        
        skillHomeScrollView.contentSize = CGSize(width: skillHomeScrollView.frame.size.width*2, height: height)
        
        masterTableView.frame = CGRect(x: 0, y: 0, width: skillHomeScrollView.frame.size.width, height: height)
        
        learningtTableView.frame = CGRect(x: masterTableView.frame.size.width, y: 0, width: skillHomeScrollView.frame.size.width, height: height)
        
    }

    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if isFirstAppear {
            isFirstAppear = false

            state = .Master
        }
    }
    
    func changeToMaster() {
        
        state = .Master
    }
    
    
    func changeToLearning() {
        
        state = .Learning
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
    

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        println("Did end decelerating \(skillHomeScrollView.contentOffset.x)")
        
        if skillHomeScrollView.contentOffset.x + 10 >= skillHomeScrollView.contentSize.width / 2.0 {
            
            state = .Learning
            
        } else {
            
            state = .Master
        }
    }
    
    func discoverUserBySkillName(skillName: String) {
        
        discoverUsers(masterSkills: [skillName], learningSkills: [], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            
            defaultFailureHandler(reason, errorMessage)
            
        }, completion: { discoveredUsers in
                
            self.discoveredMasterUsers = discoveredUsers

            dispatch_async(dispatch_get_main_queue()) {
                self.masterTableView.reloadData()
            }
        })
        
        discoverUsers(masterSkills: [], learningSkills: [skillName], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            
            defaultFailureHandler(reason, errorMessage)
            
        }, completion: { discoveredUsers in
                
            self.discoveredLearningUsers = discoveredUsers
            
            dispatch_async(dispatch_get_main_queue()) {
                self.learningtTableView.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = getDiscoveredUserWithState(state.hashValue)[indexPath.row]
                
                let vc = segue.destinationViewController as! ProfileViewController

                vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                
                vc.hidesBottomBarWhenPushed = true
                
                vc.setBackButtonWithTitle()
            }
        }
    }
    
    func getDiscoveredUserWithState(state: Int) -> [DiscoveredUser] {
        if state == SkillHomeState.Master.hashValue {
            return discoveredMasterUsers
        }else{
            return discoveredLearningUsers
        }
    }

}

extension SkillHomeViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return getDiscoveredUserWithState(tableView.tag).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        
        var discoveredUser = getDiscoveredUserWithState(tableView.tag)[indexPath.row]
        
        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
        
        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell.avatarImageView.image = roundImage
            }
        }
        
        cell.joinedDateLabel.text = discoveredUser.introduction
        
        let distance = discoveredUser.distance.format(".1")
        cell.lastTimeSeenLabel.text = "\(distance) km | \(discoveredUser.lastSignInAt.timeAgo)"
        
        cell.nameLabel.text = discoveredUser.nickname
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
    
}

