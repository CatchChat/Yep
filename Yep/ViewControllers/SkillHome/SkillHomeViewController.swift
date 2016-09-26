//
//  SkillHomeViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MobileCoreServices.UTType
import RealmSwift
import YepKit
import YepNetworking
import Proposer
import Navi

final class SkillHomeViewController: BaseViewController {

    var skill: SkillCellSkill? {
        willSet {
            title = newValue?.localName
            skillCoverURLString = newValue?.coverURLString
        }
    }

    fileprivate lazy var masterTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRect.zero)
        return tempTableView;
    }()
    
    fileprivate lazy var learningtTableView: YepChildScrollView = {
        let tempTableView = YepChildScrollView(frame: CGRect.zero)
        return tempTableView;
    }()

    fileprivate var skillCoverURLString: String? {
        willSet {
            headerView?.skillCoverURLString = newValue
        }
    }

    var afterUpdatedSkillCoverAction: (() -> Void)?

    fileprivate lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        return imagePicker
    }()
    
    fileprivate var isFirstAppear = true

    var preferedSkillSet: SkillSet?
    
    fileprivate var skillSet: SkillSet = .master {
        willSet {
            switch newValue {
            case .master:
                headerView.learningButton.setInActive(animated: !isFirstAppear)
                headerView.masterButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: !isFirstAppear)

                if discoveredMasterUsers.isEmpty {
                    discoverUsersMasterSkill()
                }
                
            case .learning:
                headerView.masterButton.setInActive(animated: !isFirstAppear)
                headerView.learningButton.setActive(animated: !isFirstAppear)
                skillHomeScrollView.setContentOffset(CGPoint(x: UIScreen.main.bounds.width, y: 0), animated: !isFirstAppear)

                if discoveredLearningUsers.isEmpty {
                    discoverUsersLearningSkill()
                }
            }
        }
    }
    
    @IBOutlet fileprivate weak var skillHomeScrollView: UIScrollView!
    
    @IBOutlet fileprivate weak var headerView: SkillHomeHeaderView!
    
    @IBOutlet fileprivate weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    fileprivate var discoveredMasterUsers = [DiscoveredUser]()
    fileprivate var discoveredLearningUsers = [DiscoveredUser]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = YepConfig.getScreenRect().height - headerView.frame.height
        
        masterTableView.frame = CGRect(x: 0, y: 0, width: YepConfig.getScreenRect().width, height: height)
        
        learningtTableView.frame = CGRect(x: masterTableView.frame.size.width, y: 0, width: YepConfig.getScreenRect().width, height: height)
        skillHomeScrollView.contentSize = CGSize(width: YepConfig.getScreenRect().width * 2, height: height)

        if isFirstAppear {
            skillSet = preferedSkillSet ?? .master

            isFirstAppear = false
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

        masterTableView.registerNibOf(ContactsCell.self)
        masterTableView.registerNibOf(LoadMoreTableViewCell.self)

        masterTableView.rowHeight = 80
        masterTableView.tableFooterView = UIView()
        masterTableView.dataSource = self
        masterTableView.delegate = self
        masterTableView.tag = SkillSet.master.rawValue

        learningtTableView.separatorColor = UIColor.yepCellSeparatorColor()
        learningtTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        learningtTableView.registerNibOf(ContactsCell.self)
        learningtTableView.registerNibOf(LoadMoreTableViewCell.self)

        learningtTableView.rowHeight = 80
        learningtTableView.tableFooterView = UIView()
        learningtTableView.dataSource = self
        learningtTableView.delegate = self
        learningtTableView.tag = SkillSet.learning.rawValue

        headerViewHeightLayoutConstraint.constant = YepConfig.skillHomeHeaderViewHeight

        /*
        headerView.masterButton.addTarget(self, action: #selector(SkillHomeViewController.changeToMaster(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        headerView.learningButton.addTarget(self, action: #selector(SkillHomeViewController.changeToLearning(_:)), forControlEvents: UIControlEvents.TouchUpInside)

        headerView.changeCoverAction = { [weak self] in

            let alertController = UIAlertController(title: NSLocalizedString("Change skill cover", comment: ""), message: nil, preferredStyle: .ActionSheet)

            let choosePhotoAction: UIAlertAction = UIAlertAction(title: String.trans_titleChoosePhoto, style: .Default) { _ in

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

                proposeToAccess(.Photos, agreed: openCameraRoll, rejected: { [weak self] in
                    self?.alertCanNotAccessCameraRoll()
                })
            }
            alertController.addAction(choosePhotoAction)

            let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { _ in

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

                proposeToAccess(.Camera, agreed: openCamera, rejected: { [weak self] in
                    self?.alertCanNotOpenCamera()
                })
            }
            alertController.addAction(takePhotoAction)

            let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .Cancel) { [weak self] _ in
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(cancelAction)
            
            self?.presentViewController(alertController, animated: true, completion: nil)

            // touch to create (if need) for faster appear
            delay(0.2) { [weak self] in
                self?.imagePicker.hidesBarsOnTap = false
            }
        }
         */

        automaticallyAdjustsScrollViewInsets = false

        skillHomeScrollView.addSubview(masterTableView)
        skillHomeScrollView.addSubview(learningtTableView)
        skillHomeScrollView.isPagingEnabled = true
        skillHomeScrollView.delegate = self
        skillHomeScrollView.isDirectionalLockEnabled = true
        skillHomeScrollView.alwaysBounceVertical = false
        skillHomeScrollView.alwaysBounceHorizontal = true

        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    skillHomeScrollView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        customTitleView()

        // Add to Me

        if let skillID = skill?.ID, let me = me() {

            let predicate = NSPredicate(format: "skillID = %@", skillID)

            let notInMaster = me.masterSkills.filter(predicate).count == 0

            if notInMaster && me.learningSkills.filter(predicate).count == 0 {
                let addSkillToMeButton = UIBarButtonItem(title: NSLocalizedString("button.add_skill_to_me", comment: ""), style: .plain, target: self, action: #selector(SkillHomeViewController.addSkillToMe(_:)))
                navigationItem.rightBarButtonItem = addSkillToMeButton
            }
        }
    }

    // MARK: UI

    fileprivate func customTitleView() {

        let titleLabel = UILabel()

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.skillHomeTextLargeFont()
        ]

        let titleAttr = NSMutableAttributedString(string: skill?.localName ?? "", attributes:textAttributes)

        titleLabel.attributedText = titleAttr
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.backgroundColor = UIColor.yepTintColor()
        titleLabel.sizeToFit()

        titleLabel.bounds = titleLabel.frame.insetBy(dx: -25.0, dy: -4.0)

        titleLabel.layer.cornerRadius = titleLabel.frame.size.height/2.0
        titleLabel.layer.masksToBounds = true

        navigationItem.titleView = titleLabel
    }

    // MARK: Actions

    @objc fileprivate func addSkillToMe(_ sender: AnyObject) {
        println("addSkillToMe")

        if let skillID = skill?.ID, let skillLocalName = skill?.localName {

            let doAddSkillToSkillSet: (SkillSet) -> Void = { skillSet in

                addSkillWithSkillID(skillID, toSkillSet: skillSet, failureHandler: { reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage)

                }, completion: { [weak self] _ in

                    let message = String.trans_promptSuccessfullyAddedSkill(skillLocalName, to: skillSet.name)
                    YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: message, dismissTitle: String.trans_titleOK, inViewController: self, withDismissAction: nil)

                    SafeDispatch.async {
                        self?.navigationItem.rightBarButtonItem = nil
                    }

                    syncMyInfoAndDoFurtherAction {
                    }
                })
            }

            let alertController = UIAlertController(title: String.trans_titleChooseSkillSet, message: String(format: NSLocalizedString("Which skill set do you want %@ to be?", comment: ""), skillLocalName), preferredStyle: .alert)

            let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { action in
            }
            alertController.addAction(cancelAction)

            let learningAction: UIAlertAction = UIAlertAction(title: SkillSet.learning.name, style: .default) { action in
                doAddSkillToSkillSet(.learning)
            }
            alertController.addAction(learningAction)

            let masterAction: UIAlertAction = UIAlertAction(title: SkillSet.master.name, style: .default) { action in
                doAddSkillToSkillSet(.master)
            }
            alertController.addAction(masterAction)

            present(alertController, animated: true, completion: nil)
        }
    }

    @objc fileprivate func changeToMaster(_ sender: AnyObject) {
        skillSet = .master
    }
    
    @objc fileprivate func changeToLearning(_ sender: AnyObject) {
        skillSet = .learning
    }

    fileprivate var masterPage = 1
    fileprivate func discoverUsersMasterSkill(isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        guard let skillID = skill?.ID else {
            return
        }

        if !isLoadMore {
            activityIndicator.startAnimating()
        }

        if isLoadMore {
            masterPage += 1

        } else {
            masterPage = 1
        }

        discoverUsersWithSkill(skillID, ofSkillSet: .master, inPage: masterPage, withPerPage: 30, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] discoveredUsers in
            SafeDispatch.async {

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

    fileprivate var learningPage = 1
    fileprivate func discoverUsersLearningSkill(isLoadMore: Bool = false, finish: (() -> Void)? = nil) {

        guard let skillID = skill?.ID else {
            return
        }

        if !isLoadMore {
            activityIndicator.startAnimating()
        }

        if isLoadMore {
            learningPage += 1

        } else {
            learningPage = 1
        }

        discoverUsersWithSkill(skillID, ofSkillSet: .learning, inPage: learningPage, withPerPage: 30, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

        }, completion: { [weak self] discoveredUsers in
            SafeDispatch.async {
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

    fileprivate func discoveredUsersWithSkillSet(_ skillSet: SkillSet?) -> [DiscoveredUser] {

        if let skillSet = skillSet {
            switch skillSet {
            case .master:
                return discoveredMasterUsers
            case .learning:
                return discoveredLearningUsers
            }

        } else {
            return []
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showProfile" {

            if let indexPath = sender as? IndexPath {

                let vc = segue.destination as! ProfileViewController

                let discoveredUser = discoveredUsersWithSkillSet(skillSet)[indexPath.row]
                vc.prepare(with: discoveredUser)
            }
        }
    }
}

// MARK: UIScrollViewDelegate

extension SkillHomeViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        guard scrollView == skillHomeScrollView else {
            return
        }

        println("Did end decelerating \(scrollView.contentOffset.x)")

        if scrollView.contentOffset.x + 10 >= scrollView.contentSize.width / 2.0 {
            if skillSet != .learning {
                skillSet = .learning
            }

        } else {
            if skillSet != .master {
                skillSet = .master
            }
        }
    }
}

// MARK: UIImagePicker

extension SkillHomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            switch mediaType {

            case String(kUTTypeImage):

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                    let fixedSize = image.yep_fixedSize

                    // resize to smaller, not need fixRotation

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: .high) {

                        let data = UIImageJPEGRepresentation(fixedImage, 0.95)

                        if let skillID = skill?.ID {

                            YepHUD.showActivityIndicator()

                            let fileExtension: FileExtension = .JPEG

                            s3UploadFileOfKind(.Avatar, withFileExtension: fileExtension, inFilePath: nil, orFileData: data, mimeType: fileExtension.mimeType, failureHandler: { [weak self] reason, errorMessage in

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

                                    SafeDispatch.async {
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
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension SkillHomeViewController: UITableViewDelegate, UITableViewDataSource {

    fileprivate enum Section: Int {
        case users
        case loadMore
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let usersCount = discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag)).count
        switch section {
        case Section.users.rawValue:
            return usersCount
        case Section.loadMore.rawValue:
            return usersCount > 0 ? 1 : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch (indexPath as NSIndexPath).section {

        case Section.users.rawValue:

            let cell: ContactsCell = tableView.dequeueReusableCell()
            
            let discoveredUser = discoveredUsersWithSkillSet(SkillSet(rawValue: tableView.tag))[indexPath.row]

            cell.configureWithDiscoveredUser(discoveredUser)

            return cell

        case Section.loadMore.rawValue:

            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        if (indexPath as NSIndexPath).section == Section.loadMore.rawValue {

            if let cell = cell as? LoadMoreTableViewCell {

                println("load more users")

                if !cell.loadingActivityIndicator.isAnimating {
                    cell.loadingActivityIndicator.startAnimating()
                }

                switch skillSet {

                case .master:
                    discoverUsersMasterSkill(isLoadMore: true, finish: { [weak cell] in
                        cell?.loadingActivityIndicator.stopAnimating()
                    })

                case .learning:
                    discoverUsersLearningSkill(isLoadMore: true, finish: { [weak cell] in
                        cell?.loadingActivityIndicator.stopAnimating()
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        switch (indexPath as NSIndexPath).section {

        case Section.users.rawValue:
            performSegue(withIdentifier: "showProfile", sender: indexPath)

        default:
            break
        }
    }
}

