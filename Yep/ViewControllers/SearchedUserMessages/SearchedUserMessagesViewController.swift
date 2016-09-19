//
//  SearchedUserMessagesViewController.swift
//  Yep
//
//  Created by NIX on 16/4/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedUserMessagesViewController: BaseViewController {

    var messages: [Message] = []
    var keyword: String? = nil

    @IBOutlet weak var messagesTableView: UITableView! {
        didSet {
            messagesTableView.separatorColor = YepConfig.SearchTableView.separatorColor
            messagesTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            messagesTableView.rowHeight = 70
            messagesTableView.tableFooterView = UIView()

            messagesTableView.registerNibOf(SearchedMessageCell)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleChatRecords
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showConversation":
            let vc = segue.destination as! ConversationViewController
            let info = (sender as! Box<[String: AnyObject]>).value
            vc.conversation = info["conversation"] as! Conversation
            vc.indexOfSearchedMessage = info["indexOfSearchedMessage"] as? Int

        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchedUserMessagesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SearchedMessageCell = tableView.dequeueReusableCell()
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        let itemIndex = (indexPath as NSIndexPath).row

        guard let
            message = messages[safe: itemIndex],
            let cell = cell as? SearchedMessageCell else {
                return
        }

        cell.configureWithMessage(message, keyword: keyword)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let itemIndex = (indexPath as NSIndexPath).row

        guard let message = messages[safe: itemIndex],
            let conversation = message.conversation,
            let realm = conversation.realm else {
                return
        }

        let conversationMessages = messagesOfConversation(conversation, inRealm: realm)
        guard let indexOfSearchedMessage = conversationMessages.indexOf(message) else {
            return
        }

        let info: [String: AnyObject] = [
            "conversation":conversation,
            "indexOfSearchedMessage": indexOfSearchedMessage,
        ]
        let sender = Box<[String: AnyObject]>(info)
        performSegue(withIdentifier: "showConversation", sender: sender)
    }
}

