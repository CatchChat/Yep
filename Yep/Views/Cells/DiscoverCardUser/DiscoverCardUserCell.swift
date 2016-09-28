//
//  DiscoverCardUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Navi

let skillTextAttributes = [NSFontAttributeName: UIFont.skillDiscoverTextFont()]

var skillCardCache = [String: UIImage?]()

final class DiscoverCardUserCell: UICollectionViewCell {
    
    @IBOutlet weak var serviceImageView: UIImageView!
    
    let skillCellIdentifier = "DiscoverSkillCell"

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var skillImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var userIntroductionLbael: UILabel!
    
    var discoveredUser: DiscoveredUser?
    
    let discoverCellHeight: CGFloat = 16
    
    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius  = 6
        contentView.layer.masksToBounds = true
        
        contentView.layer.borderColor = UIColor.yepCellSeparatorColor().cgColor
        contentView.layer.borderWidth = 1.0
        
        avatarImageView.contentMode = UIViewContentMode.scaleAspectFill
        avatarImageView.clipsToBounds = true
        skillImageView.contentMode = UIViewContentMode.scaleAspectFit
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        skillImageView.image = nil
    }
    
    func configureWithDiscoveredUser(_ discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: IndexPath) {
        
        self.discoveredUser = discoveredUser
        
        let avatarURLString = discoveredUser.avatarURLString

        let avatarSize: CGFloat = 170
        let avatarStyle: AvatarStyle = .rectangle(size: CGSize(width: avatarSize, height: avatarSize))
        let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: bigAvatarFadeTransitionDuration)

        if let accountName = discoveredUser.recently_updated_provider, let account = SocialAccount(rawValue: accountName) {
            serviceImageView.image = UIImage(named: account.iconName)
            serviceImageView.tintColor = account.tintColor
        } else {
            serviceImageView.image = nil
        }

        userIntroductionLbael.text = discoveredUser.introduction

        usernameLabel.text = discoveredUser.nickname
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.prepareSkillImage()
        }
    }
    
    fileprivate func prepareSkillImage() {

        guard let discoveredUser = discoveredUser else {
            return
        }

        var skillImage: UIImage?
    
        if let image = skillCardCache[discoveredUser.id] {
            skillImage = image

        } else {
            let skills = discoveredUser.masterSkills.count > 0 ? discoveredUser.masterSkills : discoveredUser.learningSkills
            let processedImage = genSkillImageWithSkills(skills)
            skillImage = processedImage
            skillCardCache[discoveredUser.id] = processedImage
        }
        
        SafeDispatch.async { [weak self] in
            self?.skillImageView.image = skillImage
        }
    }
    
    fileprivate func genSkillImageWithSkills(_ skills: [Skill]) -> UIImage {
        
        let maxWidth:CGFloat = 170
        
        let marginTop:CGFloat = 3.0
        
        let marginLeft: CGFloat = 6.0
        
        let lineSpacing: CGFloat = 5.0
        
        let labelMargin: CGFloat = 5.0
        
        var skillLabels = [CGRect]()
        
        //let context = UIGraphicsGetCurrentContext()
        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: 50), false, UIScreen.main.scale)
        
        for (index, skill) in skills.enumerated() {
            
            var skillLocal = skill.localName
            
            if index == 5 {
                break
            }
            
            if index == 4 {
                if skills.count > 4 && skills.count != 5 {
                    skillLocal = NSLocalizedString("\(skills.count-4) More...", comment: "")
                }
            }
            
            //// Text Drawing
            let textRect = CGRect(x: 0, y: 0, width: 0, height: 14)
            let textTextContent = NSString(string: skillLocal)
            let textStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = .center
            
            let textFontAttributes: [String: Any] = {
                let foregroundColor: UIColor
                if index == 4 && skills.count != 5 {
                    foregroundColor = UIColor.yepTintColor()
                } else {
                    foregroundColor = UIColor.white
                }
                return [
                    NSFontAttributeName: UIFont.systemFont(ofSize: 12),
                    NSParagraphStyleAttributeName: textStyle,
                    NSForegroundColorAttributeName: foregroundColor,
                ]
            }()
            
            let textTextWidth: CGFloat = textTextContent.boundingRect(with: CGSize(width: CGFloat.infinity, height: 12), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).size.width
            
            var rect = CGRect(x: 0, y: marginTop, width: textTextWidth, height: textRect.height)
            
            var lastLabel: CGRect = rect
            
            if index > 0 {
                lastLabel = skillLabels[index - 1]
            }
            
            var x = lastLabel.origin.x + lastLabel.width + labelMargin * 2
            
            var y = lastLabel.origin.y
            
            if x + rect.width + marginLeft*2 > maxWidth {
                x = 0
                y = lastLabel.origin.y + lastLabel.height + lineSpacing + marginTop*2
            }
            
            if index == 0 {
                x = 0
                y = lastLabel.origin.y
            }
            
            rect = CGRect(x: x + marginLeft, y: y, width: rect.width, height: rect.height)
            
            let rectanglePath = UIBezierPath(roundedRect: CGRect(x: rect.origin.x - marginLeft, y: rect.origin.y - marginTop, width: textTextWidth + marginLeft * 2, height: textRect.height + marginTop*2), cornerRadius: (textRect.height + marginTop*2)*0.5)
            
            let fillColor: UIColor = {
                if index == 4 && skills.count != 5 {
                   return UIColor(red: 234/255.0, green: 246/255.0, blue: 255/255.0, alpha: 1.0)
                } else {
                   return UIColor.yepTintColor()
                }
            }()
            
            fillColor.setFill()
            
            rectanglePath.fill()
            
            skillLabels.append(rect)
            
            textTextContent.draw(in: rect, withAttributes: textFontAttributes)
        }

        //CGContextSaveGState(context)
        //CGContextClipToRect(context, CGRectMake(0, 0, maxWidth, 50))
        //CGContextRestoreGState(context)
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return backgroundImage
    }
}

