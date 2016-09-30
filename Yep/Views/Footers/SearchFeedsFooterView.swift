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

    var tapKeywordAction: ((_ keyword: String) -> Void)?

    var keyword: String? {
        didSet {
            keywordButton.setTitle(keyword, for: .normal)
        }
    }

    lazy var keywordButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setTitleColor(UIColor.yepTintColor(), for: .normal)

        button.addTarget(self, action: #selector(KeywordCell.tapKeyword), for: .touchUpInside)

        return button
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {

        contentView.addSubview(keywordButton)

        keywordButton.translatesAutoresizingMaskIntoConstraints = false

        let leading = keywordButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 15)
        let centerX = keywordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        let centerY = keywordButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        let width = keywordButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        let height = keywordButton.heightAnchor.constraint(equalTo: contentView.heightAnchor)

        NSLayoutConstraint.activate([leading, centerX, centerY, width, height])
    }

    @objc fileprivate func tapKeyword() {
        if let keyword = keyword {
            tapKeywordAction?(keyword)
        }
    }
}

class SearchFeedsFooterView: UIView {

    enum Style {
        case empty
        case keywords
        case searching
        case noResults
    }

    var style: Style = .empty {
        didSet {
            switch style {

            case .empty:

                promptLabel.isHidden = true
                activityIndicatorView.stopAnimating()

                keywordsTableView.isHidden = true

            case .keywords:

                promptLabel.isHidden = false
                promptLabel.textColor = UIColor.darkGray
                promptLabel.text = NSLocalizedString("Try keywords", comment: "")

                activityIndicatorView.stopAnimating()

                keywordsTableView.isHidden = false

                if keywords.isEmpty {
                    hotWordsOfSearchFeeds(failureHandler: nil) { [weak self] hotwords in
                        self?.keywords = hotwords
                    }

                } else {
                    reloadKeywordsTableView()
                }

            case .searching:

                promptLabel.isHidden = true

                activityIndicatorView.startAnimating()

                keywordsTableView.isHidden = true

            case .noResults:

                promptLabel.isHidden = false
                promptLabel.textColor = UIColor.yep_mangmorGrayColor()
                promptLabel.text = String.trans_promptNoSearchResults

                activityIndicatorView.stopAnimating()

                keywordsTableView.isHidden = true
            }
        }
    }

    var tapBlankAction: (() -> Void)?
    var tapKeywordAction: ((_ keyword: String) -> Void)?

    var keywords: [String] = [] {
        didSet {
            reloadKeywordsTableView()
        }
    }

    lazy var promptLabel: UILabel = {

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.text = NSLocalizedString("Try any keywords", comment: "")
        return label
    }()

    lazy var activityIndicatorView: UIActivityIndicatorView = {

        let view = UIActivityIndicatorView()
        view.activityIndicatorViewStyle = .gray
        view.hidesWhenStopped = true
        return view
    }()

    lazy var keywordsTableView: UITableView = {

        let tableView = UITableView()
        tableView.registerClassOf(KeywordCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 36
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(SearchFeedsFooterView.tapBlank(_:)))
        addGestureRecognizer(tap)

        style = .empty
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func reloadKeywordsTableView() {
        SafeDispatch.async { [weak self] in
            self?.keywordsTableView.reloadData()
        }
    }

    fileprivate func makeUI() {

        addSubview(promptLabel)
        addSubview(activityIndicatorView)
        addSubview(keywordsTableView)

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        keywordsTableView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "promptLabel": promptLabel,
            "keywordsTableView": keywordsTableView,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[promptLabel]|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|-40-[promptLabel]-15-[keywordsTableView]|", options: [.alignAllCenterX, .alignAllLeading], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)

        do {
            let centerX = activityIndicatorView.centerXAnchor.constraint(equalTo: promptLabel.centerXAnchor)
            let centerY = activityIndicatorView.centerYAnchor.constraint(equalTo: promptLabel.centerYAnchor)

            NSLayoutConstraint.activate([centerX, centerY])
        }
    }

    @objc fileprivate func tapBlank(_ sender: UITapGestureRecognizer) {

        tapBlankAction?()
    }
}

extension SearchFeedsFooterView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return keywords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: KeywordCell = tableView.dequeueReusableCell()

        let keyword = keywords[indexPath.row]
        cell.keyword = keyword

        cell.tapKeywordAction = { [weak self] keyword in
            self?.tapKeywordAction?(keyword)
        }

        return cell
    }
}

