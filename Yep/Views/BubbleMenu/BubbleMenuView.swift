//
//  BubbleMenuView.swift
//  Yep
//
//  Created by NIX on 15/7/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BubbleMenuView: UIView {

    var items: [Item]

    var buttons = [UIButton]()

    struct Item {
        let title: String
        let action: BubbleMenuView -> Void
    }

    init(items: [Item]) {

        self.items = items

        super.init(frame: CGRectZero)

        makeUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    func tapButton(button: UIButton) {
        if let index = find(buttons, button) {
            let action = items[index].action
            action(self)
        }
    }

    func hide() {
        removeFromSuperview()
    }

    // MARK: UI

    let arrowHeight: CGFloat = 8
    let buttonGap: CGFloat = 12
    let offsetY: CGFloat = 8

    func makeUI() {

        backgroundColor = UIColor.clearColor()

        var format = "H:|"

        for (index, item) in enumerate(items) {

            let button = UIButton()

            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            button.setTitleColor(UIColor.lightGrayColor(), forState: .Highlighted)

            button.setTitle(item.title, forState: .Normal)
            button.addTarget(self, action: "tapButton:", forControlEvents: .TouchUpInside)

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




