//
//  YepStorageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MobileCoreServices.UTType
import Ono
import AFNetworking

struct S3UploadParams {
    let url: String
    let key: String
    let acl: String
    let algorithm: String
    let signature: String
    let date: String
    let credential: String
    let encodedPolicy: String
}


func uploadFileToS3WithFilePath(filePath: String, #s3UploadParams: S3UploadParams){

    let param = [
        "key"  : s3UploadParams.key,
        "acl"    : s3UploadParams.acl,
        "X-Amz-Algorithm": s3UploadParams.algorithm,
        "X-Amz-Signature": s3UploadParams.signature,
        "X-Amz-Date": s3UploadParams.date,
        "X-Amz-Credential": s3UploadParams.credential,
        "Policy": s3UploadParams.encodedPolicy
    ]
    
    let filename = filePath.lastPathComponent
    let mimetype = mimeTypeForPath(filePath)

    let request = AFHTTPRequestSerializer().multipartFormRequestWithMethod("POST", URLString: s3UploadParams.url, parameters: param, constructingBodyWithBlock: { formData in
        formData.appendPartWithFileURL(NSURL(fileURLWithPath: filePath)!, name: "file", fileName: filename, mimeType: mimetype, error: nil)
    }, error: nil)
    
    let manager = AFURLSessionManager(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration())
    manager.responseSerializer = AFXMLParserResponseSerializer()
    var progress: NSProgress?
    
    var uploadTask = manager.uploadTaskWithStreamedRequest(request, progress: &progress, completionHandler: { (response, responseObject, error) in
        
        if (error != nil) {
            println("Error \(error.description)")
        }else {
            println("Upload \(response) \(responseObject)")
        }
        })
    
    uploadTask.resume()

}

// MARK: Upload

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// :param: string       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        appendData(data!)
    }
}



/// Create boundary string for multipart/form-data request
///
/// :returns:            The boundary string that consists of "Boundary-" followed by a UUID string.

func generateBoundaryString() -> String {
    return "Boundary-\(NSUUID().UUIDString)"
}

/// Determine mime type on the basis of extension of a file.
///
/// This requires MobileCoreServices framework.
///
/// :param: path         The path of the file for which we are going to determine the mime type.
///
/// :returns:            Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.

func mimeTypeForPath(path: String) -> String {
    let pathExtension = path.pathExtension
    
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
        if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
    }
    return "application/octet-stream";
}

func s3UploadParams(#failureHandler: ((Reason, String?) -> ())?, #completion: S3UploadParams -> Void) {
    
    let parse: JSONDictionary -> S3UploadParams? = { data in
        println("s3FormData: \(data)")
        
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
    
    let resource = authJsonResource(path: "/api/v1/attachments/s3_upload_public_form_fields", method: .GET, requestParameters:[:], parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}
