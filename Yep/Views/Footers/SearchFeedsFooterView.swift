//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final private class KeywordCell: UITableViewCell {

    static let reuseIdentifier = "KeywordCell"

    lazy var keywordLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(18)
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

                hotWordsOfSearchFeeds(failureHandler: nil) { [weak self] hotwords in
                    self?.keywords = hotwords
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
        tableView.registerClass(KeywordCell.self, forCellReuseIdentifier: KeywordCell.reuseIdentifier)
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

        style = .Empty
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {

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

