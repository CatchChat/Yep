//
//  ShareProfileView.swift
//  Yep
//
//  Created by zhowkevin on 15/10/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ShareProfileView: UIView {

    var progress: CGFloat = 0
    
    var animating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        layer.cornerRadius = frame.height / 2.0
        
        layer.masksToBounds = true
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        imageView.image = UIImage.yep_iconShare
        
        imageView.transform = CGAffineTransform.identity.scaledBy(x: 0.4, y: 0.4)
        
        imageView.tintColor = UIColor.yepTintColor()
        
        imageView.center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
        
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateWithProgress(_ progressNew: CGFloat) {
        
        if animating {
            return
        }
        
        alpha = progressNew
        
        self.progress = progressNew
        if alpha > 1 {
            return
        }
        transform = CGAffineTransform.identity.scaledBy(x: alpha, y: alpha)
    }
    
    func shareActionAnimationAndDoFurther(_ further: @escaping () -> Void) {
        
        animating = true
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .allowUserInteraction, animations: { [weak self] in

            self?.transform = CGAffineTransform.identity.scaledBy(x: 3.0, y: 3.0)
            self?.alpha = 0
            
        }, completion: { [weak self] _ in
            
            _ = delay(0.5, work: {
                further()
                self?.animating = false
            })
        })
    }
}

