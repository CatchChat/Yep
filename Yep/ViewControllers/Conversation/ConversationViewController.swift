//
//  ConversationViewController.swift
//  Yep
//
//  Created by NIX on 15/3/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController {

    var conversation: Conversation!
    

    @IBOutlet weak var conversationCollectionView: UICollectionView!

    @IBOutlet weak var messageToolbar: MessageToolbar!
    @IBOutlet weak var messageToolbarBottomConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(13)] // TODO: 用配置来决定
    let messageTextLabelMaxWidth: CGFloat = 320 - (15+40+20) - 20 // TODO: 根据 TextCell 的布局计算


    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.conversationCollectionView.bounds)
        }()

    let chatLeftTextCellIdentifier = "ChatLeftTextCell"
    let chatRightTextCellIdentifier = "ChatRightTextCell"


    lazy var messages = [
        (true, "花谢花飞花满天，红消香断有谁怜？游丝软系飘春榭，落絮轻沾扑绣帘。闺中女儿惜春暮，愁绪满怀无释处，手把花锄出绣闺，忍踏落花来复去。柳丝榆荚自芳菲，不管桃飘与李飞。桃李明年能再发，明年闺中知有谁？"),
        (false, "三月香巢已垒成，梁间燕子太无情！明年花发虽可啄，却不道人去梁空巢也倾。一年三百六十日，风刀霜剑严相逼，明媚鲜妍能几时，一朝漂泊难寻觅。"),
        (true, "花开易见落难寻，阶前闷杀葬花人，独倚花锄泪暗洒，洒上空枝见血痕。"),
        (false, "杜鹃无语正黄昏，荷锄归去掩重门。青灯照壁人初睡，冷雨敲窗被未温。"),
        (true, "怪奴底事倍伤神，半为怜春半恼春： 怜春忽至恼忽去，至又无言去不闻。"),
        (false, "昨宵庭外悲歌发，知是花魂与鸟魂？花魂鸟魂总难留，鸟自无言花自羞。愿奴胁下生双翼，随花飞到天尽头。"),
        (true, "天尽头，何处有香丘？"),
        (false, "未若锦囊收艳骨，一抔净土掩风流。质本洁来还洁去，强于污淖陷渠沟。"),
        (true, "尔今死去侬收葬，未卜侬身何日丧？侬今葬花人笑痴，他年葬侬知是谁？"),
        (false, "试看春残花渐落，便是红颜老死时。"),
        (true, "一朝春尽红颜老，花落人亡两不知！"),
    ]


    // 使 messageToolbar 随着键盘出现或消失而移动
    var updateUIWithKeyboardChange = false {
        willSet {
            keyboardChangeObserver = newValue ? NSNotificationCenter.defaultCenter() : nil
        }
    }
    var keyboardChangeObserver: NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            oldValue?.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
            keyboardChangeObserver?.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
        }
    }


    deinit {
        updateUIWithKeyboardChange = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        conversationCollectionView.registerNib(UINib(nibName: chatLeftTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatLeftTextCellIdentifier)
        conversationCollectionView.registerNib(UINib(nibName: chatRightTextCellIdentifier, bundle: nil), forCellWithReuseIdentifier: chatRightTextCellIdentifier)

        setConversaitonCollectionViewOriginalContentInset()

        messageToolbarBottomConstraint.constant = 0

        updateUIWithKeyboardChange = true

        messageToolbar.textSendAction = { messageToolbar in
            let text = messageToolbar.messageTextField.text!

            let newMessage = (false, text)
            self.messages.append(newMessage)

            // 先重新准备 Layout
            let layout = self.conversationCollectionView.collectionViewLayout as! ConversationLayout
            layout.needUpdate = true

            // 再插入 Cell
            let newMessageIndexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
            self.conversationCollectionView.insertItemsAtIndexPaths([newMessageIndexPath])

            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                // TODO: 不使用魔法数字
                let rect = text.boundingRectWithSize(CGSize(width: self.messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: self.messageTextAttributes, context: nil)

                let height = max(rect.height + 14 + 20, 40 + 20) + 10
                self.conversationCollectionView.contentOffset.y += height

            }, completion: { (finished) -> Void in

            })

            // Clean
            messageToolbar.messageTextField.text = ""
            messageToolbar.state = .Default

            // Really Do Send Message

            sendText(text, toRecipient: self.conversation.withFriend!.userID, recipientType: "User", failureHandler: { (reason, errorMessage) -> () in
                defaultFailureHandler(reason, errorMessage)
                // TODO: sendText 错误提醒
            }, completion: { success -> Void in
                println("sendText: \(success)")
            })
        }
    }

    // MARK: Private

    private func setConversaitonCollectionViewOriginalContentInsetBottom(bottom: CGFloat) {
        var contentInset = conversationCollectionView.contentInset
        contentInset.bottom = bottom
        conversationCollectionView.contentInset = contentInset
    }

    private func setConversaitonCollectionViewOriginalContentInset() {
        setConversaitonCollectionViewOriginalContentInsetBottom(messageToolbar.intrinsicContentSize().height)
    }

    // MARK: Keyboard

    func handleKeyboardWillShowNotification(notification: NSNotification) {
        println("showKeyboard") // 在 iOS 8.3 Beat 3 里，首次弹出键盘时，这个通知会发出三次，下面设置 contentOffset 因执行多次就会导致跳动。但第二次弹出键盘就不会了

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = keyboardHeight
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentOffset.y += keyboardHeight
                self.conversationCollectionView.contentInset.bottom += keyboardHeight

            }, completion: { (finished) -> Void in
            })
        }
    }

    func handleKeyboardWillHideNotification(notification: NSNotification) {
        println("hideKeyboard")

        if let userInfo = notification.userInfo {
            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurveValue = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardEndFrame.height

            UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(animationCurveValue << 16), animations: { () -> Void in
                self.messageToolbarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()

                self.conversationCollectionView.contentOffset.y -= keyboardHeight
                self.conversationCollectionView.contentInset.bottom -= keyboardHeight

            }, completion: { (finished) -> Void in
            })
        }
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let (isFromFriend, message) = messages[indexPath.row]

        if isFromFriend {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftTextCellIdentifier, forIndexPath: indexPath) as! ChatLeftTextCell

            cell.textContentLabel.text = message

            if let conversationWithFriend = conversation.withFriend {
                AvatarCache.sharedInstance.roundAvatarOfUser(conversationWithFriend, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

            } else {
                cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(40 * 0.5)
            }

            return cell

        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRightTextCellIdentifier, forIndexPath: indexPath) as! ChatRightTextCell

            if let avatarURLString = YepUserDefaults.avatarURLString() {
                AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: 40 * 0.5) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.avatarImageView.image = roundImage
                    }
                }

            } else {
                cell.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(40 * 0.5)
            }

            cell.textContentLabel.text = message

            return cell
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        // TODO: 缓存 Cell 高度才是正道
        // TODO: 不使用魔法数字
        let (_, message) = messages[indexPath.row]
        let rect = message.boundingRectWithSize(CGSize(width: messageTextLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: messageTextAttributes, context: nil)

        let height = max(rect.height + 14 + 20, 40 + 20)
        return CGSizeMake(collectionViewWidth, height)

    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        view.endEditing(true)
    }
}


