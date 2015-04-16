//
//  RegisterSelectSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterSelectSkillsViewController: UIViewController {

    var annotationText: String = ""

    @IBOutlet weak var annotationLabel: UILabel!

    @IBOutlet weak var skillCategoriesCollectionView: UICollectionView!

    let skillCategoryCellIdentifier = "SkillCategoryCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillCategoriesCollectionView.bounds)
        }()

    var skillCategories = [
        [
            "categoryName": "Technology",
            "categoryImage": UIImage(named: "icon_skill_tech")!,
        ],
        [
            "categoryName": "Art",
            "categoryImage": UIImage(named: "icon_skill_art")!,
        ],
        [
            "categoryName": "Music",
            "categoryImage": UIImage(named: "icon_skill_music")!,
        ],
        [
            "categoryName": "Life Style",
            "categoryImage": UIImage(named: "icon_skill_life")!,
        ],
        [
            "categoryName": "Love",
            "categoryImage": UIImage(named: "icon_skill_tech")!,
        ],
        [
            "categoryName": "Hate",
            "categoryImage": UIImage(named: "icon_skill_art")!,
        ],
        [
            "categoryName": "Laugh",
            "categoryImage": UIImage(named: "icon_skill_music")!,
        ],
        [
            "categoryName": "Cry",
            "categoryImage": UIImage(named: "icon_skill_life")!,
        ],
    ]

    var currentSkillCategoryButton: SkillCategoryButton?
    var currentSkillCategoryButtonTopConstraintOriginalConstant: CGFloat = 0
    var currentSkillCategoryButtonTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        skillCategoriesCollectionView.registerNib(UINib(nibName: skillCategoryCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCategoryCellIdentifier)

        annotationLabel.text = annotationText

        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)
    }

    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension RegisterSelectSkillsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return skillCategories.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCategoryCellIdentifier, forIndexPath: indexPath) as! SkillCategoryCell

        let skillCategoryInfo = skillCategories[indexPath.item]

        cell.categoryTitle = skillCategoryInfo["categoryName"] as? String
        cell.categoryImage = skillCategoryInfo["categoryImage"] as? UIImage

        cell.toggleSelectionStateAction = { inSelectionState in

            if inSelectionState {
                
                let button = cell.skillCategoryButton
                self.currentSkillCategoryButton = button

                let frame = cell.convertRect(button.frame, toView: self.view)

                button.removeFromSuperview()

                self.view.addSubview(button)

                button.setTranslatesAutoresizingMaskIntoConstraints(false)

                let viewsDictionary = [
                    "button": button,
                ]

                let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCellConfig.skillCategoryButtonWidth)

                let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCellConfig.skillCategoryButtonHeight)

                let topConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: frame.origin.y)

                let centerXConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)

                NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, topConstraint, centerXConstraint])

                self.view.layoutIfNeeded()


                self.currentSkillCategoryButtonTopConstraint = topConstraint
                self.currentSkillCategoryButtonTopConstraintOriginalConstant = self.currentSkillCategoryButtonTopConstraint.constant

                UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in

                    topConstraint.constant = 100

                    self.view.layoutIfNeeded()

                    collectionView.alpha = 0

                }, completion: { (finished) -> Void in
                })

            } else {
                if let button = self.currentSkillCategoryButton {
                    UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in

                        self.currentSkillCategoryButtonTopConstraint.constant = self.currentSkillCategoryButtonTopConstraintOriginalConstant

                        self.view.layoutIfNeeded()

                        collectionView.alpha = 1

                    }, completion: { (_) -> Void in

                        button.removeFromSuperview()

                        cell.contentView.addSubview(button)

                        button.setTranslatesAutoresizingMaskIntoConstraints(false)

                        let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCellConfig.skillCategoryButtonWidth)

                        let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: SkillCategoryCellConfig.skillCategoryButtonHeight)

                        let centerXConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)

                        let centerYConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

                        NSLayoutConstraint.activateConstraints([widthConstraint, heightConstraint, centerXConstraint, centerYConstraint])
                    })
                }
            }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSizeMake(collectionViewWidth, SkillCategoryCellConfig.skillCategoryButtonHeight)
    }

}