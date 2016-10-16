//
//  UploadAttachmentOperation.swift
//  Yep
//
//  Created by nixzhu on 16/1/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

final public class UploadAttachmentOperation: ConcurrentOperation {

    fileprivate let uploadAttachment: UploadAttachment

    public enum Result {
        case failed(errorMessage: String?)
        case success(uploadedAttachment: UploadedAttachment)
    }
    public typealias Completion = (_ result: Result) -> Void
    fileprivate let completion: Completion

    public init(uploadAttachment: UploadAttachment, completion: @escaping Completion) {

        self.uploadAttachment = uploadAttachment
        self.completion = completion

        super.init()
    }

    override public func main() {

        tryUploadAttachment(uploadAttachment, failureHandler: { [weak self] (reason, errorMessage) in
            self?.completion(.failed(errorMessage: errorMessage))
            self?.state = .finished

        }, completion: { [weak self] uploadedAttachment in
            self?.completion(.success(uploadedAttachment: uploadedAttachment))
            self?.state = .finished
        })
    }
}

