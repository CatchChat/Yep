//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

private class KeywordCell: UITableViewCell {

    lazy var keywordLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(15)

        label.opaque = true
        label.backgroundColor = UIColor.whiteColor()
        label.clipsToBounds = true

        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(keywordLabel)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {

        let centerX = NSLayoutConstraint(item: keywordLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let centerY = NSLayoutConstraint(item: keywordLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints([centerX, centerY])
    }
}

class SearchFeedsFooterView: UIView {

    enum Style {
        case Init
        case NoResults
    }

    var style: Style = .Init {
        didSet {
            switch style {
            case .Init:
                promptLabel.textColor = UIColor.darkGrayColor()
                promptLabel.text = NSLocalizedString("Try any keywords", comment: "")
                keywordLabelA.hidden = false
                keywordLabelB.hidden = false
            case .NoResults:
                promptLabel.textColor = UIColor.yep_mangmorGrayColor()
                promptLabel.text = NSLocalizedString("No search results.", comment: "")
                keywordLabelA.hidden = true
                keywordLabelB.hidden = true
            }
        }
    }

    lazy var keywordsTableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()

    lazy var promptLabel: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFontOfSize(17)
        label.textColor = UIColor.darkGrayColor()
        label.textAlignment = .Center
        label.text = NSLocalizedString("Try any keywords", comment: "")
        return label
    }()

    lazy var keywordLabelA: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFontOfSize(13)
        label.textColor = UIColor.yepTintColor()
        label.textAlignment = .Center
        label.text = NSLocalizedString("iOS, Music ...", comment: "")
        return label
    }()

    lazy var keywordLabelB: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFontOfSize(13)
        label.textColor = UIColor.yepTintColor()
        label.textAlignment = .Center
        label.text = NSLocalizedString("Book, Food ...", comment: "")
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        style = .Init
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {
        addSubview(promptLabel)
        addSubview(keywordLabelA)
        addSubview(keywordLabelB)

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        keywordLabelA.translatesAutoresizingMaskIntoConstraints = false
        keywordLabelB.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "promptLabel": promptLabel,
            "keywordLabelA": keywordLabelA,
            "keywordLabelB": keywordLabelB,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[promptLabel]|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-80-[promptLabel]-20-[keywordLabelA]-10-[keywordLabelB]-(>=0)-|", options: [.AlignAllCenterX], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }
}

