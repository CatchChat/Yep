//
//  RegisterSelectSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import pop

class RegisterSelectSkillsViewController: UIViewController {

    var annotationText: String = ""
    var selectSkillAction: ((skill: Skill, selected: Bool) -> Bool)?
    var selectedSkillsSet = Set<Skill>()
    var anotherSelectedSkillsSet = Set<Skill>()
    var failedSelectSkillMessage: String = ""

    var syncSkillsFromServerAction: (() -> Void)?

    @IBOutlet weak var skillCategoriesCollectionView: UICollectionView!

    @IBOutlet weak var skillsCollectionView: UICollectionView!
    @IBOutlet weak var skillsCollectionViewBottomConstrain: NSLayoutConstraint!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var backButton: UIButton!

    let annotationHeight: CGFloat = 100
    @IBOutlet weak var skillsCollectionViewEqualHeightToSkillCategoriesCollectionViewConstraint: NSLayoutConstraint!

    let skillAnnotationHeaderIdentifier = "SkillAnnotationHeader"
    let skillCategoryCellIdentifier = "SkillCategoryCell"
    let skillSelectionCellIdentifier = "SkillSelectionCell"

    let skillCategoryTintColors: [UIColor] = [
        UIColor(red: 52 / 255.0, green: 152 / 255.0, blue: 219 / 255.0, alpha: 1),
        UIColor(red: 26 / 255.0, green: 188 / 255.0, blue: 156 / 255.0, alpha: 1),
        UIColor(red: 52 / 255.0, green: 73 / 255.0, blue: 94 / 255.0, alpha: 1),
        UIColor(red: 245 / 255.0, green: 166 / 255.0, blue: 35 / 255.0, alpha: 1),
    ]
    
    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillCategoriesCollectionView.bounds)
        }()

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = registerPickSkillsLayoutRightEdgeInset

    var skillCategories = [SkillCategory]()
    var skillCategoryIndex: Int = 0

    var currentSkillCategoryButton: SkillCategoryButton?
    var currentSkillCategoryButtonTopConstraintOriginalConstant: CGFloat = 0
    var currentSkillCategoryButtonTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()
        skillCategoriesCollectionView.backgroundColor = UIColor.clearColor()
        skillsCollectionView.backgroundColor = UIColor.clearColor()

        let dismissBackgroundHeight: CGFloat = 120 // not full height // 140
        let skillCategoriesCollectionViewContentInset = UIEdgeInsets(top: 0, left: 0, bottom: dismissBackgroundHeight, right: 0)
        skillCategoriesCollectionView.contentInset = skillCategoriesCollectionViewContentInset
        let skillsCollectionViewContentInset = UIEdgeInsets(top: 0, left: 0, bottom: dismissBackgroundHeight, right: 0)
        skillsCollectionView.contentInset = skillsCollectionViewContentInset

        let effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = view.bounds
        view.insertSubview(effectView, atIndex: 0)


        skillsCollectionView.alpha = 0

        skillsCollectionViewEqualHeightToSkillCategoriesCollectionViewConstraint.constant = -annotationHeight

        skillCategoriesCollectionView.registerNib(UINib(nibName: skillAnnotationHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: skillAnnotationHeaderIdentifier)
        skillsCollectionView.registerNib(UINib(nibName: skillAnnotationHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: skillAnnotationHeaderIdentifier)

        skillCategoriesCollectionView.registerNib(UINib(nibName: skillCategoryCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCategoryCellIdentifier)

        skillsCollectionView.registerNib(UINib(nibName: skillSelectionCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillSelectionCellIdentifier)

        cancelButton.setTitle(NSLocalizedString("Done", comment: ""), forState: .Normal)
        backButton.setTitle(NSLocalizedString("Back", comment: ""), forState: .Normal)

        cancelButton.alpha = 1
        backButton.alpha = 0


        let layout = self.skillCategoriesCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let originLineSpacing = layout.minimumLineSpacing

        let initialMinimumLineSpacing: CGFloat = 100
        layout.minimumLineSpacing = initialMinimumLineSpacing

        let anim = POPBasicAnimation()
        anim.beginTime = CACurrentMediaTime() + 0.0
        anim.duration = 0.9
        anim.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        let prop = POPAnimatableProperty.propertyWithName("minimumLineSpacing", initializer: { props in

            props.readBlock = { obj, values in
                values[0] = (obj as! UICollectionViewFlowLayout).minimumLineSpacing
            }
            props.writeBlock = { obj, values in
                (obj as! UICollectionViewFlowLayout).minimumLineSpacing = values[0]
            }

            props.threshold = 0.1

        }) as! POPAnimatableProperty

        anim.property = prop
        anim.fromValue = initialMinimumLineSpacing
        anim.toValue = originLineSpacing
        
        layout.pop_addAnimation(anim, forKey: "AnimateLine")


        // 如果前一个 VC 来不及传递，这里还得再请求一次
        if skillCategories.isEmpty {
            allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            }, completion: { skillCategories in
                self.skillCategories = skillCategories

                dispatch_async(dispatch_get_main_queue()) {
                    self.updateSkillsCollectionView()
                }
            })
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        skillsCollectionViewBottomConstrain.constant = -CGRectGetHeight(skillsCollectionView.bounds)
    }

    // MARK: Actions

    func updateSkillsCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.skillsCollectionView.collectionViewLayout.invalidateLayout()
            self.skillsCollectionView.reloadData()
            self.skillsCollectionView.layoutIfNeeded()
        }
    }

    @IBAction func cancel() {
        dismiss()
    }

    @IBAction func back() {
        currentSkillCategoryButton?.toggleSelectionState()
    }

    func dismiss() {
        syncSkillsFromServerAction?()
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension RegisterSelectSkillsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var reusableView: UICollectionReusableView!

        if kind == UICollectionElementKindSectionHeader {
            if collectionView == skillCategoriesCollectionView {
                let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: skillAnnotationHeaderIdentifier, forIndexPath: indexPath) as! SkillAnnotationHeader
                
                header.annotationLabel.text = annotationText
                
                let tap = UITapGestureRecognizer(target: self, action: "dismiss")
                header.annotationLabel.userInteractionEnabled = true
                header.annotationLabel.addGestureRecognizer(tap)
                
                reusableView = header

            } else {
                let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: skillAnnotationHeaderIdentifier, forIndexPath: indexPath) as! SkillAnnotationHeader

                if skillCategoryIndex < skillCategories.count {
                    let skillCategory = skillCategories[skillCategoryIndex]

                    header.annotationLabel.text = NSLocalizedString("Popular in ", comment: "") + "\(skillCategory.localName)"
                }
                
                reusableView = header
            }
        }
        
        return reusableView
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if collectionView == skillCategoriesCollectionView {
            return 1

        } else if collectionView == skillsCollectionView {
            if skillCategoryIndex < skillCategories.count {
                return 1
            }
        }

       return 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if collectionView == skillCategoriesCollectionView {

            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCategoryCellIdentifier, forIndexPath: indexPath) as! SkillCategoryCell

            let skillCategory = skillCategories[indexPath.item]

            let categoryImageNames = [
                "Art": "icon_skill_art",
                "Technology": "icon_skill_tech",
                "Sport": "icon_skill_ball",
                "Life Style": "icon_skill_life",
            ]

            cell.categoryTitle = skillCategory.localName

            if let categoryImageName = categoryImageNames[skillCategory.name] {
                cell.categoryImage = UIImage(named: categoryImageName)
            } else {
                cell.categoryImage = UIImage(named: "icon_skill_art")
            }

            let tintColor = skillCategoryTintColors[indexPath.item % skillCategoryTintColors.count]
            cell.skillCategoryButton.setBackgroundImage(UIImage(named: "button_skill_category")!.imageWithGradientTintColor(tintColor).resizableImageWithCapInsets(UIEdgeInsets(top: 30, left: 40, bottom: 30, right: 40)), forState: .Normal)

            cell.toggleSelectionStateAction = { inSelectionState in

                if inSelectionState {

                    // 刷新本次选择类别的 skills
                    self.skillCategoryIndex = indexPath.item
                    dispatch_async(dispatch_get_main_queue()) {
                        self.skillsCollectionView.reloadData()
                    }

                    let button = cell.skillCategoryButton
                    self.currentSkillCategoryButton = button

                    let frame = cell.convertRect(button.frame, toView: self.view)

                    button.removeFromSuperview()

                    self.view.addSubview(button)

                    button.translatesAutoresizingMaskIntoConstraints = false

                    let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonWidth)

                    let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonHeight)

                    let topConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: frame.origin.y)

                    let centerXConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)

                    NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, topConstraint, centerXConstraint])

                    self.view.layoutIfNeeded()


                    self.currentSkillCategoryButtonTopConstraint = topConstraint
                    self.currentSkillCategoryButtonTopConstraintOriginalConstant = self.currentSkillCategoryButtonTopConstraint.constant

                    UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in

                        topConstraint.constant = 60

                        self.view.layoutIfNeeded()

                        collectionView.alpha = 0

                    }, completion: { (finished) -> Void in
                    })
                    
                    let layout = self.skillsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
                    let originLineSpacing = layout.minimumLineSpacing
                    let anim = POPBasicAnimation()
                    anim.duration = 0.8
                    anim.timingFunction = CAMediaTimingFunction(name: "easeOut")
                    let prop = POPAnimatableProperty.propertyWithName("minimumLineSpacing", initializer: { props in
                        
                        props.readBlock = { obj, values in
                            values[0] = (obj as! UICollectionViewFlowLayout).minimumLineSpacing
                        }
                        props.writeBlock = { obj, values in
                            (obj as! UICollectionViewFlowLayout).minimumLineSpacing = values[0]
                        }
                        
                        props.threshold = 0.1
                        
                    }) as! POPAnimatableProperty
                    
                    anim.property = prop
                    anim.fromValue = 150.0
                    anim.toValue = originLineSpacing
                    
                    layout.pop_addAnimation(anim, forKey: "AnimateLine")
                    

                    UIView.animateWithDuration(0.5, delay: 0.2, options: .CurveEaseInOut, animations: { () -> Void in

                        self.skillsCollectionViewBottomConstrain.constant = 0
                        self.view.layoutIfNeeded()

                        self.skillsCollectionView.alpha = 1

                        self.cancelButton.alpha = 0
                        self.backButton.alpha = 1

                    }, completion: { (finished) -> Void in
                    })

                } else {
                    if let button = self.currentSkillCategoryButton {

                        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in

                            self.skillsCollectionView.alpha = 0
                            
                        }, completion: { (finished) -> Void in
                        })

                        UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in

                            self.currentSkillCategoryButtonTopConstraint.constant = self.currentSkillCategoryButtonTopConstraintOriginalConstant

                            self.skillsCollectionViewBottomConstrain.constant = -CGRectGetHeight(self.skillsCollectionView.bounds)
                            
                            self.view.layoutIfNeeded()

                            collectionView.alpha = 1

                            self.cancelButton.alpha = 1
                            self.backButton.alpha = 0

                        }, completion: { (_) -> Void in

                            button.removeFromSuperview()

                            cell.contentView.addSubview(button)

                            button.translatesAutoresizingMaskIntoConstraints = false

                            let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonWidth)

                            let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCell.skillCategoryButtonHeight)

                            let centerXConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)

                            let centerYConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

                            NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, centerXConstraint, centerYConstraint])
                        })
                    }
                }
            }

            return cell
            
        } else { //if collectionView == skillsCollectionView {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillSelectionCellIdentifier, forIndexPath: indexPath) as! SkillSelectionCell

            if skillCategoryIndex < skillCategories.count {
                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                cell.skillLabel.text = skill.localName

                updateSkillSelectionCell(cell, withSkill: skill)
            }
            
            return cell
        }
    }

    private func updateSkillSelectionCell(skillSelectionCell: SkillSelectionCell, withSkill skill: Skill) {

        if selectedSkillsSet.contains(skill) {
            skillSelectionCell.skillSelection = .On

        } else {
            if anotherSelectedSkillsSet.contains(skill) {
                skillSelectionCell.skillSelection = .Unavailable

            } else {
                skillSelectionCell.skillSelection = .Off
            }
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeMake(collectionViewWidth, annotationHeight)
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        if collectionView == skillCategoriesCollectionView {
            return CGSizeMake(collectionViewWidth, SkillCategoryCell.skillCategoryButtonHeight)

        } else if collectionView == skillsCollectionView {

            if skillCategoryIndex < skillCategories.count {
                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                let rect = skill.localName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillSelectionCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

                return CGSizeMake(rect.width + 24, SkillSelectionCell.height)
            }
        }

        return CGSizeZero
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        if collectionView == skillsCollectionView {
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: 0, right: sectionRightEdgeInset)
        } else {
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if collectionView == skillsCollectionView {

            if skillCategoryIndex < skillCategories.count {

                let skills = skillCategories[skillCategoryIndex].skills

                let skill = skills[indexPath.item]

                if let action = selectSkillAction {

                    let isInSet = selectedSkillsSet.contains(skill)

                    if action(skill: skill, selected: !isInSet) {
                        if isInSet {
                            selectedSkillsSet.remove(skill)
                        } else {
                            selectedSkillsSet.insert(skill)
                        }

                        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SkillSelectionCell {
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