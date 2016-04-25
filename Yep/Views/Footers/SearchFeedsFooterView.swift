//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

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

