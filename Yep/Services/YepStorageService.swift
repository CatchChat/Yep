//
//  YepStorageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MobileCoreServices.UTType
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

        case Message = "message"
        case Avatar = "avatar"
        case Feed = "topic"
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

private func uploadFileToS3(inFilePath filePath: String?, orFileData fileData: NSData?, mimeType: String, s3UploadParams: S3UploadParams, failureHandler: FailureHandler?, completion: () -> Void) {

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
    
    Alamofire.upload(
        .POST,
        s3UploadParams.url,
        multipartFormData: { multipartFormData in
            
            for parameter in parameters {
                multipartFormData.appendBodyPart(data: parameter.1.dataUsingEncoding(NSUTF8StringEncoding)!, name: parameter.0)
            }
            
            if let filePath = filePath {
                multipartFormData.appendBodyPart(fileURL: NSURL(fileURLWithPath: filePath), name: "file", fileName: filename, mimeType: mimeType)
                
            } else if let fileData = fileData {
                multipartFormData.appendBodyPart(data: fileData, name: "file", fileName: filename, mimeType: mimeType)
            }
            
        },
        encodingCompletion: { encodingResult in
            switch encodingResult {
            case .Success(let upload, _, _):
                
                upload.response { request, response, data, error in
                    
                    if let response = response {
                        print(response.statusCode)
                        
                        if response.statusCode == 204 {
                            completion()
                        } else {
                            failureHandler?(reason: .Other(nil), errorMessage: nil)
                        }

                    } else {
                        failureHandler?(reason: .Other(nil), errorMessage: nil)
                    }
                    
                }
                
            case .Failure(let encodingError):
                
                println("Error \(encodingError)")
                
                failureHandler?(reason: .Other(nil), errorMessage: nil)
            }
        }
    )
}

/// Get S3  upload params
///
///
/// :S3UploadParams:     The Upload Params

private func s3UploadParams(url: String, withFileExtension fileExtension: FileExtension, failureHandler: ((Reason, String?) -> ())?, completion: S3UploadParams -> Void) {

    let requestParameters = [
        "extname": fileExtension.rawValue
    ]

    let parse: JSONDictionary -> S3UploadParams? = { data in
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
    
    let resource = authJsonResource(path: url, method: .GET, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func s3UploadParamsOfKind(kind: S3UploadParams.Kind, withFileExtension fileExtension: FileExtension, failureHandler: FailureHandler?, completion: (S3UploadParams) -> Void) {

    s3UploadParams("/v1/attachments/\(kind.rawValue)/s3_upload_form_fields", withFileExtension: fileExtension, failureHandler: { (reason, error)  in
        if let failureHandler = failureHandler {
            failureHandler(reason: reason, errorMessage: error)
        } else {
            defaultFailureHandler(reason: reason, errorMessage: error)
        }

    }, completion: { S3PrivateUploadParams in
        completion(S3PrivateUploadParams)
    })
}

// MARK: - API

func s3UploadFileOfKind(kind: S3UploadParams.Kind, withFileExtension fileExtension: FileExtension, inFilePath filePath: String?, orFileData fileData: NSData?, mimeType: String,  failureHandler: ((Reason, String?) -> ())?, completion: S3UploadParams -> ()) {

    s3UploadParamsOfKind(kind, withFileExtension: fileExtension, failureHandler: failureHandler) { s3UploadParams in
        uploadFileToS3(inFilePath: filePath, orFileData: fileData, mimeType: mimeType, s3UploadParams: s3UploadParams, failureHandler: failureHandler) {
            completion(s3UploadParams)
        }
    }
}

