//
//  MessageMediaViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class MessageMediaViewController: UIViewController {

    var message: Message?

    @IBOutlet weak var mediaView: MediaView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let message = message {

            switch message.mediaType {

            case MessageMediaType.Image.rawValue:
                if
                    let imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
                    let image = UIImage(contentsOfFile: imageFileURL.path!) {
                        mediaView.imageView.image = image
                }

            default:
                break
            }


        }
    }

    @IBAction func swipeDown(sender: UISwipeGestureRecognizer) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
