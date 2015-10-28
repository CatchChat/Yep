//
//  DiscoverCardUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Navi

let skillTextAttributes = [NSFontAttributeName: UIFont.skillDiscoverTextFont()]

class DiscoverCardUserCell: UICollectionViewCell {
    
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
        // Initialization code
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius  = 6
        contentView.layer.masksToBounds = true
        
        contentView.layer.borderColor = UIColor.yepCellSeparatorColor().CGColor
        contentView.layer.borderWidth = 1.0
        
        avatarImageView.contentMode = UIViewContentMode.ScaleAspectFill
        avatarImageView.clipsToBounds = true
        skillImageView.contentMode = UIViewContentMode.ScaleAspectFit
    
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        skillImageView.image = nil
    }
    
    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: NSIndexPath) {
        
        self.discoveredUser = discoveredUser
        
        let avatarURLString = discoveredUser.avatarURLString

        let avatarSize: CGFloat = 170
        let avatarStyle: AvatarStyle = .Rectangle(size: CGSize(width: avatarSize, height: avatarSize))
        let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar)

        if let accountName = discoveredUser.recently_updated_provider, account = SocialAccount(rawValue: accountName) {
            serviceImageView.image = UIImage(named: account.iconName)
            serviceImageView.tintColor = account.tintColor
        } else {
            serviceImageView.image = nil
        }

        userIntroductionLbael.text = discoveredUser.introduction

        usernameLabel.text = discoveredUser.nickname
        
        prepareSkillImage()
    }
    
    func prepareSkillImage() {
        if let discoveredUser = self.discoveredUser {

            let skills = discoveredUser.masterSkills
            
            let image = genSkillImageWithSkills(skills)
            
            image.CIImage
            
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.skillImageView.image = image
            }
        }
    }
    
    func genSkillImageWithSkills(skills: [Skill]) -> UIImage {
        
        let maxWidth:CGFloat = 170
        
        let marginTop:CGFloat = 3.0
        
        let marginLeft: CGFloat = 6.0
        
        let lineSpacing: CGFloat = 5.0
        
        let labelMargin: CGFloat = 5.0
        
        var skillLabels = [CGRect]()
        
        let context = UIGraphicsGetCurrentContext()
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxWidth, height: 50), false, UIScreen.mainScreen().scale)
        
        for (index, skill) in skills.enumerate() {
            
            var skillLocal = skill.localName
            
            if index == 5 {
                
                break
            }
            
            if index == 4 {
                
                if skills.count > 4 {
                    skillLocal = NSLocalizedString("\(skills.count-4) More..", comment: "") 
                }
            }
            
            //// Text Drawing
            let textRect = CGRectMake(0, 0, 0, 14)
            let textTextContent = NSString(string: skillLocal)
            let textStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = .Center
            
            let textFontAttributes: [String: AnyObject] = {
                if index == 4 {
                    return  [NSFontAttributeName: UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor.yepTintColor(), NSParagraphStyleAttributeName: textStyle]
                } else {
                    return [NSFontAttributeName: UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: textStyle]
                }
            }()
            
            let textTextWidth: CGFloat = textTextContent.boundingRectWithSize(CGSizeMake(CGFloat.infinity, 12), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: textFontAttributes, context: nil).size.width
            
            var rect = CGRectMake(0, marginTop, textTextWidth, textRect.height)
            
            var lastLabel: CGRect = rect
            
            if index > 0 {
                lastLabel = skillLabels[index - 1]
            }
            
            var x = lastLabel.origin.x + lastLabel.width + labelMargin * 2
            
            var y = lastLabel.origin.y
            
            if x + rect.width + marginLeft*2 > maxWidth {
                x = 0
                y = lastLabel.origin.y + lastLabel.height + lineSpacing + marginTop*2
            } else if index == 0 {
                x = 0
            }
            
            rect = CGRectMake(x + marginLeft, y , rect.width, rect.height)
            
            let rectanglePath = UIBezierPath(roundedRect: CGRectMake(rect.origin.x - marginLeft, rect.origin.y - marginTop , textTextWidth + marginLeft * 2, textRect.height + marginTop*2), cornerRadius: (textRect.height + marginTop*2)*0.5)
            
            let fillColor: UIColor = {
                if index == 4 {
                   return UIColor(red: 234/255.0, green: 246/255.0, blue: 255/255.0, alpha: 1.0)
                } else {
                   return UIColor.yepTintColor()
                }
            }()
            
            fillColor.setFill()
            
            rectanglePath.fill()
            
            skillLabels.append(rect)
            
            textTextContent.drawInRect(rect, withAttributes: textFontAttributes)
        }
        
        CGContextSaveGState(context)
        CGContextClipToRect(context, CGRectMake(0, 0, maxWidth, 50))
        
        CGContextRestoreGState(context)
        
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return backgroundImage
    }



}

