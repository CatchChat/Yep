//
//  SkillHomeViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Proposer
import MobileCoreServices
import RealmSwift

enum SkillHomeState: Int {
    case Master
    case Learning
}

class SkillHomeViewController: CustomNavigationBarViewController {
    
    let cellIdentifier = "ContactsCell"
    
    lazy var masterTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRectZero)
        return tempTableView;
    }()
    
    lazy var learningtTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRectZero)
        return tempTableView;
    }()

    var skillID: String?
    
    var skillLocalName: String? {
        willSet {
            title = newValue
        }
    }
    
    var isFirstAppear = true

    var preferedState: SkillHomeState?
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
    
    @IBOutlet weak var skillHomeScrollView: YepScrollView!
    
    @IBOutlet weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    var discoveredMasterUsers = [DiscoveredUser]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.masterTableView.reloadData()
            }
        }
    }
    
    var discoveredLearningUsers = [DiscoveredUser]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.learningtTableView.reloadData()
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        masterTableView.separatorColor = UIColor.yepCellSeparatorColor()
        masterTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        masterTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        masterTableView.rowHeight = 80
        masterTableView.tableFooterView = UIView()
        masterTableView.dataSource = self
        masterTableView.delegate = self
        masterTableView.tag = SkillHomeState.Master.hashValue

        learningtTableView.separatorColor = UIColor.yepCellSeparatorColor()
        learningtTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        learningtTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        learningtTableView.rowHeight = 80
        learningtTableView.tableFooterView = UIView()
        learningtTableView.dataSource = self
        learningtTableView.delegate = self
        learningtTableView.tag = SkillHomeState.Learning.hashValue

        if let skillID = skillID {
            discoverUserBySkillID(skillID)
        }
        
        headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight
        
        headerView.masterButton.addTarget(self, action: "changeToMaster", forControlEvents: UIControlEvents.TouchUpInside)
        headerView.learningButton.addTarget(self, action: "changeToLearning", forControlEvents: UIControlEvents.TouchUpInside)

        headerView.changeCoverAction = { [weak self] in

            let openCameraRoll: ProposerAction = { [weak self] in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.sourceType = .PhotoLibrary
                    imagePicker.delegate = self
                    self?.presentViewController(imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                self?.alertCanNotAccessCameraRoll()
            })
        }
        
        automaticallyAdjustsScrollViewInsets = false
        
        skillHomeScrollView.addSubview(masterTableView)
        skillHomeScrollView.addSubview(learningtTableView)
        skillHomeScrollView.pagingEnabled = true
        skillHomeScrollView.delegate = self
        skillHomeScrollView.directionalLockEnabled = true
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    skillHomeScrollView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        customTitleView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = YepConfig.getScreenRect().height - headerView.frame.height
        
        skillHomeScrollView.contentSize = CGSize(width: skillHomeScrollView.frame.size.width*2, height: height)
        
        masterTableView.frame = CGRect(x: 0, y: 0, width: skillHomeScrollView.frame.size.width, height: height)
        
        learningtTableView.frame = CGRect(x: masterTableView.frame.size.width, y: 0, width: skillHomeScrollView.frame.size.width, height: height)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            isFirstAppear = false

            state = preferedState ?? .Master
        }
    }

    // MARK: UI

    func customTitleView() {

        let titleLabel = UILabel()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]

        let titleAttr = NSMutableAttributedString(string: skillLocalName ?? "", attributes:textAttributes)

        titleLabel.attributedText = titleAttr
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.backgroundColor = UIColor.yepTintColor()
        titleLabel.sizeToFit()

        titleLabel.bounds = CGRectInset(titleLabel.frame, -25.0, -4.0)

        titleLabel.layer.cornerRadius = titleLabel.frame.size.height/2.0
        titleLabel.layer.masksToBounds = true

        navigationItem.titleView = titleLabel
    }

    // MARK: Actions

    func changeToMaster() {
        state = .Master
    }
    
    
    func changeToLearning() {
        state = .Learning
    }

    func discoverUserBySkillID(skillID: String) {
        
        discoverUsers(masterSkillIDs: [skillID], learningSkillIDs: [], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            
        }, completion: { discoveredUsers in
            self.discoveredMasterUsers = discoveredUsers
        })
        
        discoverUsers(masterSkillIDs: [], learningSkillIDs: [skillID], discoveredUserSortStyle: .LastSignIn, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            
        }, completion: { discoveredUsers in
            self.discoveredLearningUsers = discoveredUsers
        })
    }

    func getDiscoveredUserWithState(state: Int) -> [DiscoveredUser] {

        if state == SkillHomeState.Master.hashValue {
            return discoveredMasterUsers
        } else {
            return discoveredLearningUsers
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        println("Did end decelerating \(skillHomeScrollView.contentOffset.x)")
        
        if skillHomeScrollView.contentOffset.x + 10 >= skillHomeScrollView.contentSize.width / 2.0 {
            
            state = .Learning
            
        } else {
            state = .Master
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showProfile" {

            if let indexPath = sender as? NSIndexPath {

                let discoveredUser = getDiscoveredUserWithState(state.hashValue)[indexPath.row]
                
                let vc = segue.destinationViewController as! ProfileViewController

                if discoveredUser.id != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                }
                
                vc.hidesBottomBarWhenPushed = true
                
                vc.setBackButtonWithTitle()
            }
        }
    }
}

// MARK: UIImagePicker

extension SkillHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            switch mediaType {

            case kUTTypeImage as! String:

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                    let imageWidth = image.size.width
                    let imageHeight = image.size.height

                    let fixedImageWidth: CGFloat
                    let fixedImageHeight: CGFloat

                    if imageWidth > imageHeight {
                        fixedImageWidth = min(imageWidth, YepConfig.Media.imageWidth)
                        fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
                    } else {
                        fixedImageHeight = min(imageHeight, YepConfig.Media.imageHeight)
                        fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
                    }

                    let fixedSize = CGSize(width: fixedImageWidth, height: fixedImageHeight)

                    // resize to smaller, not need fixRotation

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: kCGInterpolationMedium) {

                        let data = UIImageJPEGRepresentation(fixedImage, 0.7)

                        if let skillID = skillID {

                            s3PublicUploadFile(inFilePath: nil, orFileData: data, mimeType: "image/jpeg", failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason, errorMessage)

                                YepAlert.alertSorry(message: NSLocalizedString("Upload skill cover failed!", comment: ""), inViewController: self)

                            }, completion: { s3UploadParams in
                                let skillCoverURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

                                println("skillCoverURLString: \(skillCoverURLString)")

                                updateCoverOfSkillWithSkillID(skillID, coverURLString: skillCoverURLString, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage)

                                    YepAlert.alertSorry(message: NSLocalizedString("Update skill cover failed!", comment: ""), inViewController: self)
                                    
                                }, completion: { success in
                                    let realm = Realm()

                                    if let userSkill = userSkillWithSkillID(skillID, inRealm: realm) {

                                        println("userSkillA: \(userSkill), \(userSkill.coverURLString)")

                                        realm.write {
                                            userSkill.coverURLString = skillCoverURLString
                                        }

                                        println("userSkillB: \(userSkill), \(userSkill.coverURLString)")
                                    }
                                })
                            })
                        }
                    }
                }

            default:
                break
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension SkillHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return getDiscoveredUserWithState(tableView.tag).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        
        let discoveredUser = getDiscoveredUserWithState(tableView.tag)[indexPath.row]
        
        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5
        
        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak cell] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell?.avatarImageView.image = roundImage
            }
        }
        
        cell.joinedDateLabel.text = discoveredUser.introduction
        
        let distance = discoveredUser.distance.format(".1")
        cell.lastTimeSeenLabel.text = "\(distance) km | \(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
        
        cell.nameLabel.text = discoveredUser.nickname

        if let badgeName = discoveredUser.badge, badge = BadgeView.Badge(rawValue: badgeName) {
            cell.badgeImageView.image = badge.image
            cell.badgeImageView.tintColor = badge.color

        } else {
            cell.badgeImageView.image = nil
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
    
}

