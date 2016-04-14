//
//  SearchFeedsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchFeedsViewController: UIViewController {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    private var feedsSearchTransition: FeedsSearchTransition?

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search Feeds", comment: "")
            searchBar.setSearchFieldBackgroundImage(UIImage(named: "searchbar_textfield_background"), forState: .Normal)
            searchBar.returnKeyType = .Done
        }
    }
    @IBOutlet weak var searchBarBottomLineView: HorizontalLineView! {
        didSet {
            searchBarBottomLineView.lineColor = UIColor(white: 0.68, alpha: 1.0)
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    private var isFirstAppear = true

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isFirstAppear {
            delay(0.3) { [weak self] in
                self?.searchBar.becomeFirstResponder()
            }
            delay(0.4) { [weak self] in
                self?.searchBar.setShowsCancelButton(true, animated: true)
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let delegate = feedsSearchTransition {
            navigationController?.delegate = delegate
        }

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarTopConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }, completion: nil)

        isFirstAppear = false
    }

    // MARK: - Private

    private func hideKeyboard() {

        searchBar.resignFirstResponder()
        searchBar.yep_enableCancelButton()
    }

    private func updateResultsTableView(scrollsToTop scrollsToTop: Bool = false) {
//        dispatch_async(dispatch_get_main_queue()) { [weak self] in
//            self?.resultsTableView.reloadData()
//
//            if scrollsToTop {
//                self?.resultsTableView.yep_scrollsToTop()
//            }
//        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UISearchBarDelegate

extension SearchFeedsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {

        searchBarBottomLineView.hidden = false

        return true
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        searchBarBottomLineView.hidden = true

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        updateSearchResultsWithText(searchText)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }

    private func clearSearchResults() {

//        filteredFriends = nil
//        filteredUserMessages = nil
//        filteredFeeds = nil

        updateResultsTableView(scrollsToTop: true)
    }

    private func updateSearchResultsWithText(searchText: String) {

        guard !searchText.isEmpty else {
            clearSearchResults()

            return
        }


        //updateResultsTableView(scrollsToTop: scrollsToTop)
    }
}
