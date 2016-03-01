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

    enum Result {
        case Failed(errorMessage: String?)
        case Success(uploadedAttachment: UploadedAttachment)
    }
    typealias Completion = (result: Result) -> Void
    private let completion: Completion

    init(uploadAttachment: UploadAttachment, completion: Completion) {

        self.uploadAttachment = uploadAttachment
        self.completion = completion

        super.init()
    }

    override func main() {

        tryUploadAttachment(uploadAttachment, failureHandler: { [weak self] (reason, errorMessage) in

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            self?.completion(result: .Failed(errorMessage: errorMessage))

            self?.state = .Finished

        }, completion: { [weak self] uploadedAttachment in
            self?.completion(result: .Success(uploadedAttachment: uploadedAttachment))

            self?.state = .Finished
        })
    }
}

