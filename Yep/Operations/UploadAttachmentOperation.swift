//
//  UploadAttachmentOperation.swift
//  Yep
//
//  Created by nixzhu on 16/1/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class UploadAttachmentOperation: ConcurrentOperation {

    private let uploadAttachment: UploadAttachment
    var uploadErrorMessage: String?
    var uploadAttachmentID: String?

    init(uploadAttachment: UploadAttachment) {

        self.uploadAttachment = uploadAttachment

        super.init()
    }

    override func main() {

        tryUploadAttachment(uploadAttachment, failureHandler: { [weak self] (reason, errorMessage) in

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            self?.uploadErrorMessage = errorMessage

            self?.state = .Finished

        }, completion: { [weak self] uploadAttachmentID in
            self?.uploadAttachmentID = uploadAttachmentID

            self?.state = .Finished
        })
    }
}

