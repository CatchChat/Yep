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

    func showInView(view: UIView, withTextViewFrame textViewFrame: CGRect) {

        setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(self)

        var vConstant = CGRectGetMidY(textViewFrame) - CGRectGetMidY(view.frame)

        let menuV: NSLayoutConstraint

        switch arrowDirection {

        case .Up:
            vConstant += ceil(CGRectGetHeight(textViewFrame) * 0.5) - offsetV

            menuV = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: vConstant)

        case .Down:
            vConstant -= ceil(CGRectGetHeight(textViewFrame) * 0.5) - offsetV

            menuV = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: vConstant)
        }

        let centerXConstant = CGRectGetMidX(textViewFrame) - CGRectGetMidX(view.frame)

        let menuCenterX = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: centerXConstant)

        NSLayoutConstraint.activateConstraints([menuV, menuCenterX])
    }

    func hide() {
        removeFromSuperview()
    }

    // MARK: UI

    let arrowHeight: CGFloat = 8
    let buttonGap: CGFloat = 12
    let offsetV: CGFloat = 2

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

        UIColor.blackColor().colorWithAlphaComponent(0.7).setFill()

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




