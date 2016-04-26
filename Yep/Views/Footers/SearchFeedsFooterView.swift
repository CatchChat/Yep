//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

private class KeywordCell: UITableViewCell {

    static let reuseIdentifier = "KeywordCell"

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

        selectionStyle = .None

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {

        contentView.addSubview(keywordLabel)

        keywordLabel.translatesAutoresizingMaskIntoConstraints = false

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
                promptLabel.text = NSLocalizedString("Try keywords", comment: "")
                keywordsTableView.hidden = false
                coverView.hidden = false
            case .NoResults:
                promptLabel.textColor = UIColor.yep_mangmorGrayColor()
                promptLabel.text = NSLocalizedString("No search results.", comment: "")
                keywordsTableView.hidden = true
                coverView.hidden = true
            }
        }
    }

    var tapCoverAction: (() -> Void)?
    var tapKeywordAction: ((keyword: String) -> Void)?

    var keywords: [String] = [] {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.keywordsTableView.reloadData()
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

    lazy var keywordsTableView: UITableView = {

        let tableView = UITableView()
        tableView.registerClass(KeywordCell.self, forCellReuseIdentifier: KeywordCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 30
        tableView.scrollEnabled = false
        tableView.separatorStyle = .None
        return tableView
    }()

    lazy var coverView: UIView = {

        let view = UIView()
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)

        let tap = UITapGestureRecognizer(target: self, action: #selector(SearchFeedsFooterView.tapCoverView(_:)))
        view.addGestureRecognizer(tap)
        return view
    }()

    @objc private func tapCoverView(sender: UITapGestureRecognizer) {

        coverView.hidden = true

        tapCoverAction?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        style = .Init

        hotWordsOfSearchFeeds(failureHandler: nil) { [weak self] hotwords in
            self?.keywords = hotwords
        }
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {

        addSubview(promptLabel)
        addSubview(keywordsTableView)
        addSubview(coverView)

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        keywordsTableView.translatesAutoresizingMaskIntoConstraints = false
        coverView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "promptLabel": promptLabel,
            "keywordsTableView": keywordsTableView,
            "coverView": coverView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[promptLabel]|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-40-[promptLabel]-20-[keywordsTableView]|", options: [.AlignAllCenterX, .AlignAllLeading], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)

        do {
            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[coverView]|", options: [], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[coverView]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }
    }
}

extension SearchFeedsFooterView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return keywords.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(KeywordCell.reuseIdentifier) as! KeywordCell
        let keyword = keywords[indexPath.row]
        cell.keywordLabel.text = keyword
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        let keyword = keywords[indexPath.row]
        tapKeywordAction?(keyword: keyword)
    }
}

