//
//  RegisterSelectSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import pop

final class RegisterSelectSkillsViewController: UIViewController {

    var annotationText: String = ""
    var selectSkillAction: ((_ skill: Skill, _ selected: Bool) -> Bool)?
    var selectedSkillsSet = Set<Skill>()
    var anotherSelectedSkillsSet = Set<Skill>()
    var failedSelectSkillMessage: String = ""

    var syncSkillsFromServerAction: (() -> Void)?

    @IBOutlet weak var skillCategoriesCollectionView: UICollectionView! {
        didSet {
            skillCategoriesCollectionView.backgroundColor = UIColor.clear

            skillCategoriesCollectionView.registerHeaderNibOf(SkillAnnotationHeader.self)
            skillCategoriesCollectionView.registerNibOf(SkillCategoryCell.self)
        }
    }

    @IBOutlet weak var skillsCollectionView: UICollectionView! {
        didSet {
            skillsCollectionView.backgroundColor = UIColor.clear

            skillsCollectionView.registerHeaderNibOf(SkillAnnotationHeader.self)
            skillsCollectionView.registerNibOf(SkillSelectionCell.self)

            skillsCollectionView.alpha = 0
        }
    }
    @IBOutlet weak var skillsCollectionViewBottomConstrain: NSLayoutConstraint!

    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.setTitle(String.trans_titleDone, for: UIControlState())
            cancelButton.alpha = 1
        }
    }

    @IBOutlet weak var backButton: UIButton! {
        didSet {
            backButton.setTitle(String.trans_buttonBack, for: UIControlState())
            backButton.alpha = 0
        }
    }

    let annotationHeight: CGFloat = 100
    @IBOutlet weak var skillsCollectionViewEqualHeightToSkillCategoriesCollectionViewConstraint: NSLayoutConstraint!

    let skillCategoryTintColors: [UIColor] = [
        UIColor(red: 52 / 255.0, green: 152 / 255.0, blue: 219 / 255.0, alpha: 1),
        UIColor(red: 26 / 255.0, green: 188 / 255.0, blue: 156 / 255.0, alpha: 1),
        UIColor(red: 52 / 255.0, green: 73 / 255.0, blue: 94 / 255.0, alpha: 1),
        UIColor(red: 245 / 255.0, green: 166 / 255.0, blue: 35 / 255.0, alpha: 1),
    ]
    
    lazy var collectionViewWidth: CGFloat = {
        return self.skillCategoriesCollectionView.bounds.width
    }()

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = registerPickSkillsLayoutRightEdgeInset

    var skillCategories = [SkillCategory]()
    var skillCategoryIndex: Int = 0

    var currentSkillCategoryButton: SkillCategoryButton?
    var currentSkillCategoryButtonTopConstraintOriginalConstant: CGFloat = 0
    var currentSkillCategoryButtonTopConstraint: NSLayoutConstraint!

    let categoryImageNames = [
        "Art": "icon_skill_art",
        "Technology": "icon_skill_tech",
        "Sport": "icon_skill_ball",
        "Life Style": "icon_skill_life",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        let dismissBackgroundHeight: CGFloat = 120 // not full height // 140
        let skillCategoriesCollectionViewContentInset = UIEdgeInsets(top: 0, left: 0, bottom: dismissBackgroundHeight, right: 0)
        skillCategoriesCollectionView.contentInset = skillCategoriesCollectionViewContentInset
        let skillsCollectionViewContentInset = UIEdgeInsets(top: 0, left: 0, bottom: dismissBackgroundHeight, right: 0)
        skillsCollectionView.contentInset = skillsCollectionViewContentInset

        let effect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = view.bounds
        view.insertSubview(effectView, at: 0)

        skillsCollectionViewEqualHeightToSkillCategoriesCollectionViewConstraint.constant = -annotationHeight

        let layout = self.skillCategoriesCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let originLineSpacing = layout.minimumLineSpacing

        let initialMinimumLineSpacing: CGFloat = 100
        layout.minimumLineSpacing = initialMinimumLineSpacing

        let anim = POPBasicAnimation()
        anim.beginTime = CACurrentMediaTime() + 0.0
        anim.duration = 0.9
        anim.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        let prop = POPAnimatableProperty.property(withName: "minimumLineSpacing", initializer: { props in

            props?.readBlock = { obj, values in
                values?[0] = (obj as! UICollectionViewFlowLayout).minimumLineSpacing
            }
            props?.writeBlock = { obj, values in
                (obj as! UICollectionViewFlowLayout).minimumLineSpacing = (values?[0])!
            }

            props?.threshold = 0.1

        }) as! POPAnimatableProperty

        anim.property = prop
        anim.fromValue = initialMinimumLineSpacing
        anim.toValue = originLineSpacing
        
        layout.pop_add(anim, forKey: "AnimateLine")

        // 如果前一个 VC 来不及传递，这里还得再请求一次
        if skillCategories.isEmpty {
            allSkillCategories(failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { [weak self] skillCategories in
                self?.skillCategories = skillCategories

                SafeDispatch.async { [weak self] in
                    self?.updateSkillsCollectionView()
                }
            })
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        skillsCollectionViewBottomConstrain.constant = -skillsCollectionView.bounds.height
    }

    // MARK: Actions

    func updateSkillsCollectionView() {
        SafeDispatch.async { [weak self] in
            self?.skillsCollectionView.collectionViewLayout.invalidateLayout()
            self?.skillsCollectionView.reloadData()
            self?.skillsCollectionView.layoutIfNeeded()
        }
    }

    @IBAction func cancel() {
        doDismiss()
    }

    @IBAction func back() {
        currentSkillCategoryButton?.toggleSelectionState()
    }

    func doDismiss() {
        syncSkillsFromServerAction?()
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension RegisterSelectSkillsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        var reusableView: UICollectionReusableView!

        if kind == UICollectionElementKindSectionHeader {

            let header: SkillAnnotationHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, forIndexPath: indexPath)

            if collectionView == skillCategoriesCollectionView {

                header.annotationLabel.text = annotationText
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(RegisterSelectSkillsViewController.doDismiss))
                header.annotationLabel.isUserInteractionEnabled = true
                header.annotationLabel.addGestureRecognizer(tap)
                
            } else {
                if skillCategoryIndex < skillCategories.count {
                    let skillCategory = skillCategories[skillCategoryIndex]

                    header.annotationLabel.text = NSLocalizedString("Popular in ", comment: "") + "\(skillCategory.localName)"
                }
            }

            reusableView = header
        }
        
        return reusableView
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == skillCategoriesCollectionView {
            return 1

        } else if collectionView == skillsCollectionView {
            if skillCategoryIndex < skillCategories.count {
                return 1
            }
        }

       return 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == skillCategoriesCollectionView {
            return skillCategories.count

        } else if collectionView == skillsCollectionView {

            if skillCategoryIndex < skillCategories.count {
                let skills = skillCategories[skillCategoryIndex].skills
                return skills.count
            }
        }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == skillCategoriesCollectionView {

            let cell: SkillCategoryCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            let skillCategory = skillCategories[indexPath.item]

            cell.categoryTitle = skillCategory.localName

            if let categoryImageName = categoryImageNames[skillCategory.name] {
                cell.categoryImage = UIImage(named: categoryImageName)
            } else {
                cell.categoryImage = UIImage.yep_iconSkillArt
            }

            let tintColor = skillCategoryTintColors[(indexPath as NSIndexPath).item % skillCategoryTintColors.count]
            cell.skillCategoryButton.setBackgroundImage(UIImage.yep_buttonSkillCategory.imageWithGradientTintColor(tintColor).resizableImage(withCapInsets: UIEdgeInsets(top: 30, left: 40, bottom: 30, right: 40)), for: .normal)

            cell.toggleSelectionStateAction = { [weak self, weak cell] inSelectionState in

                guard let strongSelf = self, let cell = cell else {
                    return
                }

                if inSelectionState {

                    // 刷新本次选择类别的 skills
                    strongSelf.skillCategoryIndex = (indexPath as NSIndexPath).item
                    SafeDispatch.async { [weak self] in
                        self?.skillsCollectionView.reloadData()
                    }

                    guard let button = cell.skillCategoryButton else {
                        return
                    }

                    strongSelf.currentSkillCategoryButton = button

                    let frame = cell.convert(button.frame, to: strongSelf.view)

                    button.removeFromSuperview()

                    strongSelf.view.addSubview(button)

                    button.translatesAutoresizingMaskIntoConstraints = false

                    let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonWidth)

                    let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonHeight)

                    let topConstraint = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: strongSelf.view, attribute: .top, multiplier: 1, constant: frame.origin.y)

                    let centerXConstraint = NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: strongSelf.view, attribute: .centerX, multiplier: 1, constant: 0)

                    NSLayoutConstraint.activate([widthConstraint, heightConstraint, topConstraint, centerXConstraint])

                    strongSelf.view.layoutIfNeeded()


                    strongSelf.currentSkillCategoryButtonTopConstraint = topConstraint
                    strongSelf.currentSkillCategoryButtonTopConstraintOriginalConstant = strongSelf.currentSkillCategoryButtonTopConstraint.constant

                    UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: { [weak self] in

                        topConstraint.constant = 60

                        self?.view.layoutIfNeeded()

                        collectionView.alpha = 0

                    }, completion: nil)
                    
                    let layout = strongSelf.skillsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
                    let originLineSpacing = layout.minimumLineSpacing
                    let anim = POPBasicAnimation()
                    anim.duration = 0.8
                    anim.timingFunction = CAMediaTimingFunction(name: "easeOut")
                    let prop = POPAnimatableProperty.property(withName: "minimumLineSpacing", initializer: { props in
                        
                        props?.readBlock = { obj, values in
                            values?[0] = (obj as! UICollectionViewFlowLayout).minimumLineSpacing
                        }
                        props?.writeBlock = { obj, values in
                            (obj as! UICollectionViewFlowLayout).minimumLineSpacing = (values?[0])!
                        }
                        
                        props?.threshold = 0.1
                        
                    }) as! POPAnimatableProperty
                    
                    anim.property = prop
                    anim.fromValue = 150.0
                    anim.toValue = originLineSpacing
                    
                    layout.pop_add(anim, forKey: "AnimateLine")
                    

                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: { [weak self] in

                        self?.skillsCollectionViewBottomConstrain.constant = 0
                        self?.view.layoutIfNeeded()

                        self?.skillsCollectionView.alpha = 1

                        self?.cancelButton.alpha = 0
                        self?.backButton.alpha = 1

                    }, completion: nil)

                } else {
                    if let button = strongSelf.currentSkillCategoryButton {

                        UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: { [weak self] in

                            self?.skillsCollectionView.alpha = 0
                            
                        }, completion: nil)

                        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: { [weak self] in

                            guard let strongSelf = self else {
                                return
                            }

                            strongSelf.currentSkillCategoryButtonTopConstraint.constant = strongSelf.currentSkillCategoryButtonTopConstraintOriginalConstant

                            strongSelf.skillsCollectionViewBottomConstrain.constant = -strongSelf.skillsCollectionView.bounds.height
                            
                            strongSelf.view.layoutIfNeeded()

                            collectionView.alpha = 1

                            strongSelf.cancelButton.alpha = 1
                            strongSelf.backButton.alpha = 0

                        }, completion: { _ in

                            button.removeFromSuperview()

                            cell.contentView.addSubview(button)

                            button.translatesAutoresizingMaskIntoConstraints = false

                            let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonWidth)

                            let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonHeight)

                            let centerXConstraint = NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1, constant: 0)

                            let centerYConstraint = NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: cell.contentView, attribute: .centerY, multiplier: 1, constant: 0)

                            NSLayoutConstraint.activate([widthConstraint, heightConstraint, centerXConstraint, centerYConstraint])
                        })
                    }
                }
            }

            return cell
            
        } else { //if collectionView == skillsCollectionView {
            let cell: SkillSelectionCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            if skillCategoryIndex < skillCategories.count {
                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                cell.skillLabel.text = skill.localName

                updateSkillSelectionCell(cell, withSkill: skill)
            }
            
            return cell
        }
    }

    fileprivate func updateSkillSelectionCell(_ skillSelectionCell: SkillSelectionCell, withSkill skill: Skill) {

        if selectedSkillsSet.contains(skill) {
            skillSelectionCell.skillSelection = .on

        } else {
            if anotherSelectedSkillsSet.contains(skill) {
                skillSelectionCell.skillSelection = .unavailable

            } else {
                skillSelectionCell.skillSelection = .off
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionViewWidth, height: annotationHeight)
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        if collectionView == skillCategoriesCollectionView {
            return CGSize(width: collectionViewWidth, height: SkillCategoryCell.skillCategoryButtonHeight)

        } else if collectionView == skillsCollectionView {

            if skillCategoryIndex < skillCategories.count {
                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                let rect = skill.localName.boundingRect(with: CGSize(width: CGFloat(FLT_MAX), height: SkillSelectionCell.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: skillTextAttributes, context: nil)

                return CGSize(width: rect.width + 24, height: SkillSelectionCell.height)
            }
        }

        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        if collectionView == skillsCollectionView {
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: 0, right: sectionRightEdgeInset)
        } else {
            return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if collectionView == skillsCollectionView {

            if skillCategoryIndex < skillCategories.count {

                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                if let action = selectSkillAction {

                    let isInSet = selectedSkillsSet.contains(skill)

                    if action(skill, !isInSet) {
                        if isInSet {
                            selectedSkillsSet.remove(skill)
                        } else {
                            selectedSkillsSet.insert(skill)
                        }

                        if let cell = collectionView.cellForItem(at: indexPath) as? SkillSelectionCell {
                            updateSkillSelectionCell(cell, withSkill: skill)
                        }

                    } else {
                        YepAlert.alertSorry(message: failedSelectSkillMessage, inViewController: self)
                    }
                }
            }
        }
    }
}

