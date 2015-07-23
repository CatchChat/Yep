//
//  BubbleMenuView.swift
//  Yep
//
//  Created by NIX on 15/7/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BubbleMenuView: UIView {

    var titles: [String]

    var buttons = [UIButton]()

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: CGRectZero)

        makeUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let arrowHeight: CGFloat = 8
    let buttonGap: CGFloat = 12

    func makeUI() {

        //backgroundColor = UIColor.redColor()
        backgroundColor = UIColor.clearColor()

        var format = "H:|"

        for (index, title) in enumerate(titles) {

            let button = UIButton()
            //button.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.5)

            button.setTitle(title, forState: .Normal)
            button.setTranslatesAutoresizingMaskIntoConstraints(false)

            addSubview(button)

            buttons.append(button)

            if index == 0 {
                format += "-[button\(index)]"
            } else {
                format += "-(\(buttonGap))-[button\(index)(==button0)]"
            }
        }

        format += "-|"

        //let format = "H:|[label0][label1][label2]|"

        var views = [NSObject: AnyObject]()

        for (index, button) in enumerate(buttons) {
            let key = "button\(index)"
            views[key] = button
        }

        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .AlignAllCenterY, metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(hConstraints)

        if let firstButton = buttons.first {

            let firstButtonTop = NSLayoutConstraint(item: firstButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
            let firstButtonBottom = NSLayoutConstraint(item: firstButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -arrowHeight)

            NSLayoutConstraint.activateConstraints([firstButtonTop, firstButtonBottom])
        }
    }

//    override func intrinsicContentSize() -> CGSize {
//        return CGSize(width: 80 * titles.count, height: 80)
//    }


    override func drawRect(rect: CGRect) {

        UIColor.blackColor().colorWithAlphaComponent(0.7).setFill()

        // bubble

        var roundedRect = rect
        roundedRect.size.height -= arrowHeight
        let bubblePath = UIBezierPath(roundedRect: roundedRect, cornerRadius: 5)
        bubblePath.fill()


        // arrow

        let buttomX = CGRectGetMidX(rect)
        let buttomY = CGRectGetMaxY(rect)

        let arrowPath = UIBezierPath()
        arrowPath.moveToPoint(CGPointMake(buttomX, buttomY))
        arrowPath.addLineToPoint(CGPointMake(buttomX - (arrowHeight - 1), buttomY - arrowHeight))
        arrowPath.addLineToPoint(CGPointMake(buttomX + (arrowHeight - 1), buttomY - arrowHeight))
        arrowPath.closePath()
        arrowPath.fill()


        // lines

        UIColor.whiteColor().colorWithAlphaComponent(0.3).setStroke()

        for (index, button) in enumerate(buttons) {
            if index > 0 {
                let line = UIBezierPath()

                let x = CGRectGetMinX(button.frame) - buttonGap * 0.5
                let y = CGRectGetMaxY(rect)

                line.moveToPoint(CGPoint(x: x , y: 0))
                line.addLineToPoint(CGPoint(x: x, y: y))

                line.lineWidth = 1

                line.stroke()
            }
        }
    }

}




