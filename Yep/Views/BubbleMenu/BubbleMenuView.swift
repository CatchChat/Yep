//
//  BubbleMenuView.swift
//  Yep
//
//  Created by NIX on 15/7/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class BubbleMenuView: UIView {

    enum ArrowDirection {
        case Up
        case Down
    }

    struct Item {

        enum Type {
            case Normal
            case Danger
        }
        let type: Type

        let title: String

        let action: BubbleMenuView -> Void
    }

    var arrowDirection: ArrowDirection
    var items: [Item]

    var buttons = [UIButton]()

    init(arrowDirection: ArrowDirection, items: [Item]) {

        self.arrowDirection = arrowDirection
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

    func showInView(view: UIView, withBubbleFrame bubbleFrame: CGRect) {

        // position

        setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(self)

        var vConstant = CGRectGetMidY(bubbleFrame) - CGRectGetMidY(view.frame)

        let menuV: NSLayoutConstraint

        switch arrowDirection {

        case .Up:
            vConstant += ceil(CGRectGetHeight(bubbleFrame) * 0.5) - offsetV

            menuV = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: vConstant)

        case .Down:
            vConstant -= ceil(CGRectGetHeight(bubbleFrame) * 0.5) - offsetV

            menuV = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: vConstant)
        }

        let centerXConstant = CGRectGetMidX(bubbleFrame) - CGRectGetMidX(view.frame)

        let menuCenterX = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: centerXConstant)

        NSLayoutConstraint.activateConstraints([menuV, menuCenterX])


        // animation

        transform = CGAffineTransformMakeScale(0.0001, 0.0001)

        UIView.animateWithDuration(0.25, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(0), animations: { _ in
            self.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }, completion: { finished in
            self.transform = CGAffineTransformIdentity
        })
    }

    func hide() {

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.transform = CGAffineTransformMakeScale(0.0001, 0.0001)

        }, completion: { finished in
            self.removeFromSuperview()
        })
    }

    // MARK: UI

    let arrowHeight: CGFloat = 8
    let buttonGap: CGFloat = 16
    let offsetV: CGFloat = -1

    func makeUI() {

        backgroundColor = UIColor.clearColor()

        var format = "H:|"

        for (index, item) in enumerate(items) {

            let button = UIButton()

            switch item.type {

            case .Normal:

                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                button.setTitleColor(UIColor.lightGrayColor(), forState: .Highlighted)

            case .Danger:

                let dangerRed = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)

                button.setTitleColor(dangerRed, forState: .Normal)
                button.setTitleColor(dangerRed.colorWithAlphaComponent(0.3), forState: .Highlighted)
            }

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

            switch arrowDirection {

            case .Up:

                let firstButtonTop = NSLayoutConstraint(item: firstButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: arrowHeight)
                let firstButtonBottom = NSLayoutConstraint(item: firstButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)

                NSLayoutConstraint.activateConstraints([firstButtonTop, firstButtonBottom])

            case .Down:

                let firstButtonTop = NSLayoutConstraint(item: firstButton, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
                let firstButtonBottom = NSLayoutConstraint(item: firstButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -arrowHeight)

                NSLayoutConstraint.activateConstraints([firstButtonTop, firstButtonBottom])
            }
        }
    }

    override func drawRect(rect: CGRect) {

        UIColor.blackColor().colorWithAlphaComponent(0.6).setFill()

        // bubble

        var roundedRect = rect

        switch arrowDirection {

        case .Up:
            roundedRect.origin.y += arrowHeight
            roundedRect.size.height -= arrowHeight

        case .Down:
            roundedRect.size.height -= arrowHeight
        }

        let bubblePath = UIBezierPath(roundedRect: roundedRect, cornerRadius: 5)
        bubblePath.fill()


        // arrow

        switch arrowDirection {

        case .Up:
            let topX = CGRectGetMidX(rect)
            let topY = CGRectGetMinY(rect)

            let arrowPath = UIBezierPath()
            arrowPath.moveToPoint(CGPointMake(topX, topY))
            arrowPath.addLineToPoint(CGPointMake(topX - (arrowHeight - 1), topY + arrowHeight))
            arrowPath.addLineToPoint(CGPointMake(topX + (arrowHeight - 1), topY + arrowHeight))
            arrowPath.closePath()
            arrowPath.fill()

        case .Down:
            let buttomX = CGRectGetMidX(rect)
            let buttomY = CGRectGetMaxY(rect)

            let arrowPath = UIBezierPath()
            arrowPath.moveToPoint(CGPointMake(buttomX, buttomY))
            arrowPath.addLineToPoint(CGPointMake(buttomX - (arrowHeight - 1), buttomY - arrowHeight))
            arrowPath.addLineToPoint(CGPointMake(buttomX + (arrowHeight - 1), buttomY - arrowHeight))
            arrowPath.closePath()
            arrowPath.fill()
        }


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




