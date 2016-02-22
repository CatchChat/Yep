//
//  SkillHomeViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MobileCoreServices
import RealmSwift
import Proposer
import Navi

let ScrollViewTag = 100

class SkillHomeViewController: BaseViewController {

    var skill: SkillCell.Skill? {
        willSet {
            title = newValue?.localName
            skillCoverURLString = newValue?.coverURLString
        }
    }

    private lazy var masterTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRectZero)
        return tempTableView;
    }()
    
    private lazy var learningtTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRectZero)
        return tempTableView;
    }()

    private var skillCoverURLString: String? {
        willSet {
            headerView?.skillCoverURLString = newValue
        }
    }

    var afterUpdatedSkillCoverAction: (() -> Void)?

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        return imagePicker
    }()
    
    private var isFirstAppear = true

    var preferedSkillSet: SkillSet?
    
    private var skillSet: SkillSet = .Master {
        willSet {
            switch newValue {
            case .Master:
                headerView.learningButton.setInActive(animated: !isFirstAppear)
                headerView.masterButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: !isFirstAppear)

                if discoveredMasterUsers.isEmpty {
                    discoverUsersMasterSkill()
                }
                
            case .Learning:
                headerView.masterButton.setInActive(animated: !isFirstAppear)
                headerView.learningButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: UIScreen.mainScreen().bounds.width, y: 0), animated: !isFirstAppear)

                if discoveredLearningUsers.isEmpty {
                    discoverUsersLearningSkill()
                }
            }
        }
    }
    
    @IBOutlet private weak var skillHomeScrollView: UIScrollView!
    
    @IBOutlet private weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet private weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var discoveredMasterUsers = [DiscoveredUser]()
    private var discoveredLearningUsers = [DiscoveredUser]()
    
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

    private let cellIdentifier = "ContactsCell"
    private let loadMoreTableViewCellID = "LoadMoreTableViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let skillCategory = skill?.category {
            headerView.skillCategory = skillCategory
        }
        headerView.skillCoverURLString = skillCoverURLString

        masterTableView.separatorColor = UIColor.yepCellSeparatorColor()
        masterTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        masterTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        masterTableView.registerNib(UINib(nibName: loadMoreTableViewCellID, bundle: nil), forCellReuseIdentifier: loadMoreTableViewCellID)
        masterTableView.rowHeight = 80
        masterTableView.tableFooterView = UIView()
        masterTableView.dataSource = self
        masterTableView.delegate = self
        masterTableView.tag = SkillSet.Master.rawValue

        learningtTableView.separatorColor = UIColor.yepCellSeparatorColor()
        learningtTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        learningtTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        learningtTableView.registerNib(UINib(nibName: loadMoreTableViewCellID, bundle: nil), forCellReuseIdentifier: loadMoreTableViewCellID)
        learningtTableView.rowHeight = 80
        learningtTableView.tableFooterView = UIView()
        learningtTableView.dataSource = self
        learningtTableView.delegate = self
        learningtTableView.tag = SkillSet.Learning.rawValue

        headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight
        
        headerView.masterButton.addTarget(self, action: "changeToMaster:", forControlEvents: UIControlEvents.TouchUpInside)
        
        headerView.learningButton.addTarget(self, action: "changeToLearning:", forControlEvents: UIControlEvents.TouchUpInside)

        headerView.changeCoverAction = { [weak self] in

            let alertController = UIAlertController(title: NSLocalizedString("Change skill cover", comment: ""), message: nil, preferredStyle: .ActionSheet)

            let choosePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Choose Photo", comment: ""), style: .Default) { action -> Void in

                let openCameraRoll: ProposerAction = { [weak self] in

                    guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                        self?.alertCanNotAccessCameraRoll()
                        return
                    }

                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .PhotoLibrary
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                }

                proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                    self?.alertCanNotAccessCameraRoll()
                })
            }
            alertController.addAction(choosePhotoAction)

            let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { action -> Void in

                let openCamera: ProposerAction = { [weak self] in

                    guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                        self?.alertCanNotOpenCamera()
                        return
                    }

                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .Camera
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
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

        // Add to Me

        if let skillID = skill?.ID {
            if let
                myUserID = YepUserDefaults.userID.value,
                realm = try? Realm(),
                me = userWithUserID(myUserID, inRealm: realm) {

                    let predicate = NSPredicate(format: "skillID = %@", skillID)

                    if me.masterSkills.filter(predicate).count == 0
                        && me.learningSkills.filter(predicate).count == 0 {
                            let addSkillToMeButton = UIBarButtonItem(title: NSLocalizedString("Add to Me", comment: ""), style: .Plain, target: self, action: "addSkillToMe:")
                            navigationItem.rightBarButtonItem = addSkillToMeButton
                    }
            }
        }
    }

    // MARK: UI

    private func customTitleView() {

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

    @objc private func addSkillToMe(sender: AnyObject) {
        println("addSkillToMe")

        if let skillID = skill?.ID, skillLocalName = skill?.localName {

            let doAddSkillToSkillSet: SkillSet -> Void = { skillSet in

                addSkillWithSkillID(skillID, toSkillSet: skillSet, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                }, completion: { [weak self] _ in

                    YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: String(format: NSLocalizedString("Added %@ to %@ successfully!", comment: ""), skillLocalName, skillSet.name), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: nil)

                    dispatch_async(dispatch_get_main_queue()) {
                        self?.navigationItem.rightBarButtonItem = nil
                    }

                    syncMyInfoAndDoFurtherAction {
                    }
                })
            }

            let alertController = UIAlertController(title: NSLocalizedString("Choose skill set", comment: ""), message: String(format: NSLocalizedString("Which skill set do you want %@ to be?", comment: ""), skillLocalName), preferredStyle: .Alert)

            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action in
            }
            alertController.addAction(cancelAction)

            let learningAction: UIAlertAction = UIAlertAction(title: SkillSet.Learning.name, style: .Default) { action in
                doAddSkillToSkillSet(.Learning)
            }
            alertController.addAction(learningAction)

            let masterAction: UIAlertAction = UIAlertAction(title: SkillSet.Master.name, style: .Default) { action in
                doAddSkillToSkillSet(.Master)
            }
            alertController.addAction(masterAction)

            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    @objc private func changeToMaster(sender: AnyObject) {
        skillSet = .Master
    }
    
    @objc private func changeToLearning(sender: AnyObject) {
        skillSet = .Learning
    }

    private var masterPage = 1
    private func discoverUsersMasterSkill(isLoadMore isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        guard let skillID = skill?.ID else {
            return
        }

        if !isLoadMore {
            activityIndicator.startAnimating()
        }

        if isLoadMore {
            masterPage++

        } else {
            masterPage = 1
        }

        discoverUsersWithSkill(skillID, ofSkillSet: .Master, inPage: masterPage, withPerPage: 30, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] discoveredUsers in
            dispatch_async(dispatch_get_main_queue()) {

                if isLoadMore {
                    self?.discoveredMasterUsers += discoveredUsers
                } else {
                    self?.discoveredMasterUsers = discoveredUsers
                }

                finish?()

                self?.activityIndicator.stopAnimating()

                if !discoveredUsers.isEmpty {
                    self?.masterTableView.reloadData()
                }
            }
        })
    }

    private var learningPage = 1
    private func discoverUsersLearningSkill(isLoadMore isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        guard let skillID = skill?.ID else {
            return
        }

        if !isLoadMore {
            activityIndicator.startAnimating()
        }

        if isLoadMore {
            learningPage++

        } else {
            learningPage = 1
        }

        discoverUsersWithSkill(skillID, ofSkillSet: .Learning, inPage: learningPage, withPerPage: 30, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] discoveredUsers in
            dispatch_async(dispatch_get_main_queue()) {
                if isLoadMore {
                    self?.discoveredLearningUsers += discoveredUsers
                } else {
                    self?.discoveredLearningUsers = discoveredUsers
                }

                finish?()

                self?.activityIndicator.stopAnimating()

                if !discoveredUsers.isEmpty {
                    self?.learningtTableView.reloadData()
                }
            }
        })
    }

    private func discoveredUsersWithSkillSet(skillSet: SkillSet?) -> [DiscoveredUser] {

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

// MARK: UIScrollViewDelegate

extension SkillHomeViewController: UIScrollViewDelegate {
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
}

// MARK: UIImagePicker

extension SkillHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

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

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: .Medium) {

                        let data = UIImageJPEGRepresentation(fixedImage, 0.7)

                        if let skillID = skill?.ID {

                            YepHUD.showActivityIndicator()

                            let fileExtension: FileExtension = .JPEG

                            s3UploadFileOfKind(.Avatar, withFileExtension: fileExtension, inFilePath: nil, orFileData: data, mimeType: fileExtension.mimeType, failureHandler: { [weak self] reason, errorMessage in

                                YepHUD.hideActivityIndicator()

                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                                YepAlert.alertSorry(message: NSLocalizedString("Upload skill cover failed!", comment: ""), inViewController: self)

                            }, completion: { s3UploadParams in

                                let skillCoverURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

                                updateCoverOfSkillWithSkillID(skillID, coverURLString: skillCoverURLString, failureHandler: { [weak self] reason, errorMessage in

                                    YepHUD.hideActivityIndicator()

                                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                                    YepAlert.alertSorry(message: NSLocalizedString("Update skill cover failed!", comment: ""), inViewController: self)
                                    
                                }, completion: { [weak self] success in

                                    dispatch_async(dispatch_get_main_queue()) {
                                        guard let realm = try? Realm() else {
                                            return
                                        }

                                        if let userSkill = userSkillWithSkillID(skillID, inRealm: realm) {

                                            let _ = try? realm.write {
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

    private enum Section: Int {
        case Users
        case LoadMore
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let usersCount = discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag)).count
        switch section {
        case Section.Users.rawValue:
            return usersCount
        case Section.LoadMore.rawValue:
            return usersCount > 0 ? 1 : 0
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.section {

        case Section.Users.rawValue:

            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
            
            let discoveredUser = discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag))[indexPath.row]

            cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)

            return cell

        case Section.LoadMore.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(loadMoreTableViewCellID) as! LoadMoreTableViewCell
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == Section.LoadMore.rawValue {

            if let cell = cell as? LoadMoreTableViewCell {

                println("load more users")

                if !cell.loadingActivityIndicator.isAnimating() {
                    cell.loadingActivityIndicator.startAnimating()
                }

                switch skillSet {

                case .Master:
                    discoverUsersMasterSkill(isLoadMore: true, finish: { [weak cell] in
                        cell?.loadingActivityIndicator.stopAnimating()
                    })

                case .Learning:
                    discoverUsersLearningSkill(isLoadMore: true, finish: { [weak cell] in
                        cell?.loadingActivityIndicator.stopAnimating()
                    })
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        switch indexPath.section {

        case Section.Users.rawValue:
            performSegueWithIdentifier("showProfile", sender: indexPath)

        default:
            break
        }
    }
}

