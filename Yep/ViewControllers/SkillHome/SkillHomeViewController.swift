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

let ScrollViewTag = 100

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

    var skill: SkillCell.Skill? {
        willSet {
            title = newValue?.localName
            skillCoverURLString = newValue?.coverURLString
        }
    }

    var skillCoverURLString: String? {
        willSet {
            headerView?.skillCoverURLString = newValue
        }
    }

    var afterUpdatedSkillCoverAction: (() -> Void)?

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        return imagePicker
        }()
    
    var isFirstAppear = true

    var preferedSkillSet: SkillSet?
    
    var skillSet: SkillSet = .Master {
        willSet {
            switch newValue {
            case .Master:
                headerView.learningButton.setInActive(animated: !isFirstAppear)
                headerView.masterButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: !isFirstAppear)
                
            case .Learning:
                headerView.masterButton.setInActive(animated: !isFirstAppear)
                headerView.learningButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: UIScreen.mainScreen().bounds.width, y: 0), animated: !isFirstAppear)
            }
        }
    }
    
    @IBOutlet weak var skillHomeScrollView: UIScrollView!
    
    @IBOutlet weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var statusBarShouldLight = true
    
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarShouldLight = true

        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        let height = YepConfig.getScreenRect().height - headerView.frame.height
        
        masterTableView.frame = CGRect(x: 0, y: 0, width: YepConfig.getScreenRect().width, height: height)
        
        learningtTableView.frame = CGRect(x: masterTableView.frame.size.width, y: 0, width: YepConfig.getScreenRect().width, height: height)
        skillHomeScrollView.contentSize = CGSize(width: YepConfig.getScreenRect().width * 2, height: height)

        if isFirstAppear {
            skillSet = preferedSkillSet ?? .Master

            isFirstAppear = false
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if statusBarShouldLight {
            return UIStatusBarStyle.LightContent
        } else {
            return UIStatusBarStyle.Default
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let skillCategory = skill?.category {
            headerView.skillCategory = skillCategory
        }
        headerView.skillCoverURLString = skillCoverURLString

        masterTableView.separatorColor = UIColor.yepCellSeparatorColor()
        masterTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        masterTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        masterTableView.rowHeight = 80
        masterTableView.tableFooterView = UIView()
        masterTableView.dataSource = self
        masterTableView.delegate = self
        masterTableView.tag = SkillSet.Master.rawValue

        learningtTableView.separatorColor = UIColor.yepCellSeparatorColor()
        learningtTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        learningtTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        learningtTableView.rowHeight = 80
        learningtTableView.tableFooterView = UIView()
        learningtTableView.dataSource = self
        learningtTableView.delegate = self
        learningtTableView.tag = SkillSet.Learning.rawValue

        if let skillID = skill?.ID {
            discoverUserBySkillID(skillID)
        }
        
        headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight
        
        headerView.masterButton.addTarget(self, action: "changeToMaster", forControlEvents: UIControlEvents.TouchUpInside)
        
        headerView.learningButton.addTarget(self, action: "changeToLearning", forControlEvents: UIControlEvents.TouchUpInside)

        headerView.changeCoverAction = { [weak self] in

            let alertController = UIAlertController(title: NSLocalizedString("Change skill cover", comment: ""), message: nil, preferredStyle: .ActionSheet)

            let choosePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Choose Photo", comment: ""), style: .Default) { action -> Void in

                let openCameraRoll: ProposerAction = { [weak self] in
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
                        if let strongSelf = self {
                            strongSelf.imagePicker.sourceType = .PhotoLibrary
                            strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                        }
                    }
                }

                proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                    self?.alertCanNotAccessCameraRoll()
                })
            }
            alertController.addAction(choosePhotoAction)

            let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { action -> Void in

                let openCamera: ProposerAction = { [weak self] in
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                        if let strongSelf = self {
                            strongSelf.imagePicker.sourceType = .Camera
                            strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                        }
                    }
                }

                proposeToAccess(.Camera, agreed: openCamera, rejected: {
                    self?.alertCanNotOpenCamera()
                })
            }
            alertController.addAction(takePhotoAction)

            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(cancelAction)
            
            self?.presentViewController(alertController, animated: true, completion: nil)

            // touch to create (if need) for faster appear
            delay(0.2) {
                self?.imagePicker.hidesBarsOnTap = false
            }
        }

        automaticallyAdjustsScrollViewInsets = false
        

        
        skillHomeScrollView.addSubview(masterTableView)
        skillHomeScrollView.addSubview(learningtTableView)
        skillHomeScrollView.pagingEnabled = true
        skillHomeScrollView.delegate = self
        skillHomeScrollView.directionalLockEnabled = true
        skillHomeScrollView.alwaysBounceVertical = false
        skillHomeScrollView.alwaysBounceHorizontal = true
        skillHomeScrollView.tag = ScrollViewTag
        
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        statusBarShouldLight = true
        
        self.setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: UI

    func customTitleView() {

        let titleLabel = UILabel()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]

        let titleAttr = NSMutableAttributedString(string: skill?.localName ?? "", attributes:textAttributes)

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
        skillSet = .Master
    }
    
    
    func changeToLearning() {
        skillSet = .Learning
    }

    func discoverUserBySkillID(skillID: String) {

        activityIndicator.startAnimating()
        
        discoverUsers(masterSkillIDs: [skillID], learningSkillIDs: [], discoveredUserSortStyle: .LastSignIn, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }
            
        }, completion: { [weak self] discoveredUsers in
            dispatch_async(dispatch_get_main_queue()) {
                self?.discoveredMasterUsers = discoveredUsers
                self?.activityIndicator.stopAnimating()
            }
        })
        
        discoverUsers(masterSkillIDs: [], learningSkillIDs: [skillID], discoveredUserSortStyle: .LastSignIn, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }
            
        }, completion: { [weak self] discoveredUsers in
            dispatch_async(dispatch_get_main_queue()) {
                self?.discoveredLearningUsers = discoveredUsers
                self?.activityIndicator.stopAnimating()
            }
        })
    }

    func discoveredUsersWithSkillSet(skillSet: SkillSet?) -> [DiscoveredUser] {

        if let skillSet = skillSet {
            switch skillSet {
            case .Master:
                return discoveredMasterUsers
            case .Learning:
                return discoveredLearningUsers
            }

        } else {
            return []
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if scrollView.tag != ScrollViewTag {
            return
        }
        
        println("Did end decelerating \(skillHomeScrollView.contentOffset.x)")
        
        if skillHomeScrollView.contentOffset.x + 10 >= skillHomeScrollView.contentSize.width / 2.0 {
            
            if skillSet != .Learning {
                skillSet = .Learning
            }
            
        } else {
            if skillSet != .Master {
                skillSet = .Master
            }
           
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showProfile" {

            if let indexPath = sender as? NSIndexPath {

                let discoveredUser = discoveredUsersWithSkillSet(skillSet)[indexPath.row]
                
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

                        if let skillID = skill?.ID {

                            YepHUD.showActivityIndicator()

                            s3PublicUploadFile(inFilePath: nil, orFileData: data, mimeType: "image/jpeg", failureHandler: { [weak self] reason, errorMessage in

                                YepHUD.hideActivityIndicator()

                                defaultFailureHandler(reason, errorMessage)
                                YepAlert.alertSorry(message: NSLocalizedString("Upload skill cover failed!", comment: ""), inViewController: self)

                            }, completion: { s3UploadParams in

                                let skillCoverURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

                                updateCoverOfSkillWithSkillID(skillID, coverURLString: skillCoverURLString, failureHandler: { [weak self] reason, errorMessage in

                                    YepHUD.hideActivityIndicator()

                                    defaultFailureHandler(reason, errorMessage)
                                    YepAlert.alertSorry(message: NSLocalizedString("Update skill cover failed!", comment: ""), inViewController: self)
                                    
                                }, completion: { [weak self] success in

                                    dispatch_async(dispatch_get_main_queue()) {
                                        let realm = Realm()

                                        if let userSkill = userSkillWithSkillID(skillID, inRealm: realm) {

                                            realm.write {
                                                userSkill.coverURLString = skillCoverURLString
                                            }

                                            self?.skillCoverURLString = skillCoverURLString
                                            self?.afterUpdatedSkillCoverAction?()
                                        }
                                    }

                                    YepHUD.hideActivityIndicator()
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

        return discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag)).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        
        let discoveredUser = discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag))[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
    
}

