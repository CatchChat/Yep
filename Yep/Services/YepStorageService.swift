//
//  YepStorageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MobileCoreServices.UTType
import YepKit
import YepNetworking
import Alamofire

/**
    Struct of S3 UploadParams
*/

struct S3UploadParams {

    let url: String
    let key: String
    let acl: String
    let algorithm: String
    let signature: String
    let date: String
    let credential: String
    let encodedPolicy: String

    enum Kind: String {

        case message = "message"
        case avatar = "avatar"
        case feed = "topic"
    }
}

/**
    Upload file to S3 with upload Params

    Use filePath or fileData

    - parameter filePath:  File Path, can be nil
    - parameter fileData:  File NSData, can be nil
    - parameter mimetype:  File type like image/png

    - returns: Bool  upload status
*/

private func uploadFileToS3(inFilePath filePath: String?, orFileData fileData: Data?, mimeType: String, s3UploadParams: S3UploadParams, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parameters: [String: String] = [
        "key": s3UploadParams.key,
        "acl": s3UploadParams.acl,
        "X-Amz-Algorithm": s3UploadParams.algorithm,
        "X-Amz-Signature": s3UploadParams.signature,
        "X-Amz-Date": s3UploadParams.date,
        "X-Amz-Credential": s3UploadParams.credential,
        "Policy": s3UploadParams.encodedPolicy
    ]
    
    let filename = "attachment"

    Alamofire.upload(multipartFormData: { multipartFormData in

        for (key, value) in parameters {
            multipartFormData.append(value.data(using: .utf8)!, withName: key)
        }

        if let filePath = filePath {
            multipartFormData.append(URL(fileURLWithPath: filePath), withName: "file", fileName: filename, mimeType: mimeType)

        } else if let fileData = fileData {
            multipartFormData.append(fileData, withName: "file", fileName: filename, mimeType: mimeType)
        }

    }, to: s3UploadParams.url, method: .post, encodingCompletion: { encodingResult in

        switch encodingResult {

        case .success(let upload, _, _):

            upload.response { (dataResponse) in

                if let response = dataResponse.response {
                    print(response.statusCode)

                    if response.statusCode == 204 {
                        completion()
                    } else {
                        failureHandler?(.other(nil), nil)
                    }

                } else {
                    failureHandler?(.other(nil), nil)
                }

            }

        case .failure(let encodingError):

            println("Error \(encodingError)")

            failureHandler?(.other(nil), nil)
        }
    })
}

/// Get S3  upload params
///
///
/// :S3UploadParams:     The Upload Params

private func s3UploadParams(_ url: String, withFileExtension fileExtension: FileExtension, failureHandler: ((Reason, String?) -> ())?, completion: @escaping (S3UploadParams) -> Void) {

    let requestParameters = [
        "extname": fileExtension.rawValue
    ]

    let parse: (JSONDictionary) -> S3UploadParams? = { data in
        //println("s3FormData: \(data)")
        
        if let options = data["options"] as? JSONDictionary {
            if
                let encodedPolice = options["encoded_policy"] as? String,
                let key = options["key"] as? String,
                let signature = options["signature"] as? String,
                let urlString = options["url"] as? String,
                let policy = options["policy"] as? JSONDictionary,
                let conditions = policy["conditions"] as? [JSONDictionary] {

                    var acl: String?
                    var credential: String?
                    var algorithm: String?
                    var date: String?
                    
                    for dict in conditions {
                        for (key, value) in dict {
                            switch key {
                            case "acl":
                                acl = value as? String
                            case "x-amz-credential":
                                credential = value as? String
                            case "x-amz-algorithm":
                                algorithm = value as? String
                            case "x-amz-date":
                                date = value as? String
                            default:
                                break
                            }
                        }
                    }
                    
                    if let acl = acl, let credential = credential, let algorithm = algorithm, let date = date {
                        return S3UploadParams(url: urlString, key: key, acl: acl, algorithm: algorithm, signature: signature, date: date, credential: credential, encodedPolicy: encodedPolice)
                    }
            }
        }
    
        return nil
    }
    
    let resource = authJsonResource(path: url, method: .get, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func s3UploadParamsOfKind(_ kind: S3UploadParams.Kind, withFileExtension fileExtension: FileExtension, failureHandler: FailureHandler?, completion: @escaping (S3UploadParams) -> Void) {

    s3UploadParams("/v1/attachments/\(kind.rawValue)/s3_upload_form_fields", withFileExtension: fileExtension, failureHandler: { (reason, error)  in
        let failureHandler: FailureHandler = { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            failureHandler?(reason, errorMessage)
        }
        failureHandler(reason, error)

    }, completion: { S3PrivateUploadParams in
        completion(S3PrivateUploadParams)
    })
}

// MARK: - API

func s3UploadFileOfKind(_ kind: S3UploadParams.Kind, withFileExtension fileExtension: FileExtension, inFilePath filePath: String?, orFileData fileData: Data?, mimeType: String,  failureHandler: ((Reason, String?) -> ())?, completion: @escaping (S3UploadParams) -> ()) {

    s3UploadParamsOfKind(kind, withFileExtension: fileExtension, failureHandler: failureHandler) { s3UploadParams in
        uploadFileToS3(inFilePath: filePath, orFileData: fileData, mimeType: mimeType, s3UploadParams: s3UploadParams, failureHandler: failureHandler) {
            completion(s3UploadParams)
        }
    }
}

