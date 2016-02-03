//
//  ShareProfileView.swift
//  Yep
//
//  Created by zhowkevin on 15/10/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ShareProfileView: UIView {

    var progress: CGFloat = 0
    
    var animating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.whiteColor()
        
        layer.cornerRadius = frame.height / 2.0
        
        layer.masksToBounds = true
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        imageView.image = UIImage(named: "icon_share")
        
        imageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4)
        
        imageView.tintColor = UIColor.yepTintColor()
        
        imageView.center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateWithProgress(progressNew: CGFloat) {
        
        if animating {
            return
        }
        
        alpha = progressNew
        
        self.progress = progressNew
        if alpha > 1 {
            return
        }
        transform = CGAffineTransformScale(CGAffineTransformIdentity, alpha, alpha)
    }
    
    func shareActionAnimationAndDoFurther(further: () -> Void) {
        
        animating = true
        
        UIView.animateKeyframesWithDuration(0.3, delay: 0, options: UIViewKeyframeAnimationOptions.AllowUserInteraction, animations: { [weak self] in
            
            self?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 3.0, 3.0)
            self?.alpha = 0
            
        }, completion: { [weak self] _ in
            
            delay(0.5, work: { 
                further()
                self?.animating = false
            })
        })
    }
}

