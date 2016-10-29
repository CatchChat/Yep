//
//  MeetGeniusViewController.swift
//  Yep
//
//  Created by NIX on 16/5/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import RealmSwift
import Ruler

final class MeetGeniusViewController: UIViewController, CanScrollsToTop {

    var tapBannerAction: ((_ banner: GeniusInterviewBanner) -> Void)?
    var showGeniusInterviewAction: ((_ geniusInterview: GeniusInterview) -> Void)?

    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.addSubview(self.refreshControl)

            tableView.tableFooterView = UIView()

            tableView.separatorInset = UIEdgeInsets(top: 0, left: 95, bottom: 0, right: 0)

            tableView.registerNibOf(GeniusInterviewCell.self)
            tableView.registerNibOf(LoadMoreTableViewCell.self)
        }
    }

    var interviewsTableView: UITableView {
        return tableView
    }

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return tableView
    }

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self, action: #selector(MeetGeniusViewController.refresh(_:)), for: .valueChanged)
        refreshControl.layer.zPosition = -1
        return refreshControl
    }()

    fileprivate lazy var meetGeniusShowView: MeetGeniusShowView = {
        let view = MeetGeniusShowView(frame: CGRect(x: 0, y: 0, width: 100, height: 180))
        view.tapAction = { [weak self] banner in
            self?.tapBannerAction?(banner)
        }
        return view
    }()

    fileprivate lazy var noGeniusInterviewsFooterView: InfoView = InfoView(String.trans_promptNoInterviews)
    fileprivate lazy var fetchFailedFooterView: InfoView = InfoView(String.trans_errorFetchFailed)

    fileprivate var geniusInterviews: [GeniusInterview] = []

    func geniusInterviewAtIndexPath(_ indexPath: IndexPath) -> GeniusInterview {
        return geniusInterviews[indexPath.row]
    }

    fileprivate var canLoadMore: Bool = false
    fileprivate var isFetchingGeniusInterviews: Bool = false

    deinit {
        println("deinit MeetGenius")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            tableView.tableHeaderView = self.meetGeniusShowView
            meetGeniusShowView.getLatestGeniusInterviewBanner()
        }

        do {
            if let realm = try? Realm(), let offlineJSON = OfflineJSON.withName(.geniusInterviews, inRealm: realm) {
                if let data = offlineJSON.JSON {
                    if let geniusInterviewsData = data["genius_interviews"] as? [JSONDictionary] {
                        let geniusInterviews: [GeniusInterview] = geniusInterviewsData.map({ GeniusInterview($0) }).flatMap({ $0 })
                        self.geniusInterviews = geniusInterviews
                    }
                }
            }

            updateGeniusInterviews()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshControl.endRefreshing()
    }

    fileprivate enum UpdateGeniusInterviewsMode {
        case top
        case loadMore
    }

    fileprivate func updateGeniusInterviews(mode: UpdateGeniusInterviewsMode = .top, finish: (() -> Void)? = nil) {

        if isFetchingGeniusInterviews {
            finish?()
            return
        }

        isFetchingGeniusInterviews = true

        let maxNumber: Int?
        switch mode {
        case .top:
            canLoadMore = true
            maxNumber = nil
        case .loadMore:
            maxNumber = geniusInterviews.last?.number
        }

        let failureHandler: FailureHandler = { reason, errorMessage in

            SafeDispatch.async { [weak self] in

                if case .top = mode {
                    self?.geniusInterviews = []
                    self?.tableView.reloadData()
                }

                self?.tableView.tableFooterView = self?.fetchFailedFooterView

                self?.isFetchingGeniusInterviews = false

                finish?()
            }
        }

        let count: Int = Ruler.universalHorizontal(10, 12, 15, 20, 25).value
        geniusInterviewsWithCount(count, afterNumber: maxNumber, failureHandler: failureHandler, completion: { [weak self] geniusInterviews in

            SafeDispatch.async { [weak self] in

                if case .top = mode, geniusInterviews.isEmpty {
                    self?.tableView.tableFooterView = self?.noGeniusInterviewsFooterView
                } else {
                    self?.tableView.tableFooterView = UIView()
                }

                guard let strongSelf = self else {
                    return
                }

                strongSelf.canLoadMore = (geniusInterviews.count == count)

                let newGeniusInterviews = geniusInterviews
                let oldGeniusInterviews = strongSelf.geniusInterviews

                var wayToUpdate: UITableView.WayToUpdate = .none

                if oldGeniusInterviews.isEmpty {
                    wayToUpdate = .reloadData
                }

                switch mode {

                case .top:
                    strongSelf.geniusInterviews = newGeniusInterviews

                    if Set(oldGeniusInterviews.map({ $0.number })) == Set(newGeniusInterviews.map({ $0.number })) {
                        wayToUpdate = .none

                    } else {
                        wayToUpdate = .reloadData
                    }

                case .loadMore:
                    let oldGeniusInterviewsCount = oldGeniusInterviews.count

                    let oldGeniusInterviewNumberSet = Set<Int>(oldGeniusInterviews.map({ $0.number }))
                    var realNewGeniusInterviews = [GeniusInterview]()
                    for geniusInterview in newGeniusInterviews {
                        if !oldGeniusInterviewNumberSet.contains(geniusInterview.number) {
                            realNewGeniusInterviews.append(geniusInterview)
                        }
                    }
                    strongSelf.geniusInterviews += realNewGeniusInterviews

                    let newGeniusInterviewsCount = strongSelf.geniusInterviews.count

                    let indexPaths = Array(oldGeniusInterviewsCount..<newGeniusInterviewsCount).map({ IndexPath(row: $0, section: Section.geniusInterview.rawValue) })
                    if !indexPaths.isEmpty {
                        wayToUpdate = .insert(indexPaths)
                    }
                }

                wayToUpdate.performWithTableView(strongSelf.tableView)

                self?.isFetchingGeniusInterviews = false

                finish?()
            }
        })
    }

    @objc fileprivate func refresh(_ sender: UIRefreshControl) {

        meetGeniusShowView.getLatestGeniusInterviewBanner()

        updateGeniusInterviews(mode: .top) {
            SafeDispatch.async {
                sender.endRefreshing()
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension MeetGeniusViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case geniusInterview
        case loadMore
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .geniusInterview:
            return geniusInterviews.count

        case .loadMore:
            return geniusInterviews.isEmpty ? 0 : 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .geniusInterview:
            let cell: GeniusInterviewCell = tableView.dequeueReusableCell()
            let geniusInterview = geniusInterviews[indexPath.row]
            cell.configure(withGeniusInterview: geniusInterview)
            return cell

        case .loadMore:
            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            cell.noMoreResultsLabel.text = NSLocalizedString("To be continue.", comment: "")
            cell.isLoading = true
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .geniusInterview:
            break

        case .loadMore:
            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            guard canLoadMore else {
                cell.isLoading = false
                break
            }

            println("load more geniusInterviews")

            if !cell.isLoading {
                cell.isLoading = true
            }

            updateGeniusInterviews(mode: .loadMore, finish: {
                _ = delay(0.5) { [weak cell] in
                    cell?.isLoading = false
                }
            })
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .geniusInterview:
            return 105

        case .loadMore:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .geniusInterview:
            let geniusInterview = geniusInterviews[indexPath.row]
            showGeniusInterviewAction?(geniusInterview)

        case .loadMore:
            break
        }
    }
}

