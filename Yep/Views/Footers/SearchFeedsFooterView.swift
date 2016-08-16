//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final private class KeywordCell: UITableViewCell {

    var tapKeywordAction: ((keyword: String) -> Void)?

    var keyword: String? {
        didSet {
            keywordButton.setTitle(keyword, forState: .Normal)
        }
    }

    lazy var keywordButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(18)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)

        button.addTarget(self, action: #selector(KeywordCell.tapKeyword), forControlEvents: .TouchUpInside)

        return button
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

        contentView.addSubview(keywordButton)

        keywordButton.translatesAutoresizingMaskIntoConstraints = false

        let leading = keywordButton.leadingAnchor.constraintGreaterThanOrEqualToAnchor(contentView.leadingAnchor, constant: 15)
        let centerX = keywordButton.centerXAnchor.constraintEqualToAnchor(contentView.centerXAnchor)
        let centerY = keywordButton.centerYAnchor.constraintEqualToAnchor(contentView.centerYAnchor)
        let width = keywordButton.widthAnchor.constraintGreaterThanOrEqualToConstant(60)
        let height = keywordButton.heightAnchor.constraintEqualToAnchor(contentView.heightAnchor)

        NSLayoutConstraint.activateConstraints([leading, centerX, centerY, width, height])
    }

    @objc private func tapKeyword() {
        if let keyword = keyword {
            tapKeywordAction?(keyword: keyword)
        }
    }
}

class SearchFeedsFooterView: UIView {

    enum Style {
        case Empty
        case Keywords
        case Searching
        case NoResults
    }

    var style: Style = .Empty {
        didSet {
            switch style {

            case .Empty:

                promptLabel.hidden = true
                activityIndicatorView.stopAnimating()

                keywordsTableView.hidden = true

            case .Keywords:

                promptLabel.hidden = false
                promptLabel.textColor = UIColor.darkGrayColor()
                promptLabel.text = NSLocalizedString("Try keywords", comment: "")

                activityIndicatorView.stopAnimating()

                keywordsTableView.hidden = false

                if keywords.isEmpty {
                    hotWordsOfSearchFeeds(failureHandler: nil) { [weak self] hotwords in
                        self?.keywords = hotwords
                    }

                } else {
                    reloadKeywordsTableView()
                }

            case .Searching:

                promptLabel.hidden = true

                activityIndicatorView.startAnimating()

                keywordsTableView.hidden = true

            case .NoResults:

                promptLabel.hidden = false
                promptLabel.textColor = UIColor.yep_mangmorGrayColor()
                promptLabel.text = NSLocalizedString("No search results.", comment: "")

                activityIndicatorView.stopAnimating()

                keywordsTableView.hidden = true
            }
        }
    }

    var tapBlankAction: (() -> Void)?
    var tapKeywordAction: ((keyword: String) -> Void)?

    var keywords: [String] = [] {
        didSet {
            reloadKeywordsTableView()
        }
    }

    lazy var promptLabel: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFontOfSize(20)
        label.textColor = UIColor.darkGrayColor()
        label.textAlignment = .Center
        label.text = NSLocalizedString("Try any keywords", comment: "")
        return label
    }()

    lazy var activityIndicatorView: UIActivityIndicatorView = {

        let view = UIActivityIndicatorView()
        view.activityIndicatorViewStyle = .Gray
        view.hidesWhenStopped = true
        return view
    }()

    lazy var keywordsTableView: UITableView = {

        let tableView = UITableView()
        tableView.registerClassOf(KeywordCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 36
        tableView.scrollEnabled = false
        tableView.separatorStyle = .None
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(SearchFeedsFooterView.tapBlank(_:)))
        addGestureRecognizer(tap)

        style = .Empty
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reloadKeywordsTableView() {
        SafeDispatch.async { [weak self] in
            self?.keywordsTableView.reloadData()
        }
    }

    private func makeUI() {

        addSubview(promptLabel)
        addSubview(activityIndicatorView)
        addSubview(keywordsTableView)

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        keywordsTableView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: AnyObject] = [
            "promptLabel": promptLabel,
            "keywordsTableView": keywordsTableView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[promptLabel]|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-40-[promptLabel]-15-[keywordsTableView]|", options: [.AlignAllCenterX, .AlignAllLeading], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)

        do {
            let centerX = activityIndicatorView.centerXAnchor.constraintEqualToAnchor(promptLabel.centerXAnchor)
            let centerY = activityIndicatorView.centerYAnchor.constraintEqualToAnchor(promptLabel.centerYAnchor)

            NSLayoutConstraint.activateConstraints([centerX, centerY])
        }
    }

    @objc private func tapBlank(sender: UITapGestureRecognizer) {

        tapBlankAction?()
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

        let cell: KeywordCell = tableView.dequeueReusableCell()

        let keyword = keywords[indexPath.row]
        cell.keyword = keyword

        cell.tapKeywordAction = { [weak self] keyword in
            self?.tapKeywordAction?(keyword: keyword)
        }

        return cell
    }
}

