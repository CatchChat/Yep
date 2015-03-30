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
import AWSS3
import AFNetworking
/// Create request
///
/// :param: userid   The userid to be passed to web service
/// :param: password The password to be passed to web service
/// :param: email    The email address to be passed to web service
///
/// :returns:         The NSURLRequest that was created

func createRequest(#url:NSURL, #filePath: String, #key: String, #acl: String, #algorithm: String, #signature: String, #date: String, #credential: String, #policy: String) -> NSURLRequest {
    let param = [
        ["key"  : key],
        ["acl"    : acl],
        ["X-Amz-Algorithm": algorithm],
        ["X-Amz-Signature": signature],
        ["X-Amz-Date": date],
        ["X-Amz-Credential": credential],
        ["Policy": policy]
    ]  // build your dictionary however appropriate
    
    let boundary = generateBoundaryString()
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"

    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    request.HTTPBody = createBodyWithParameters(parameters: param, filePathKey: "file", paths: [filePath], boundary: boundary)
    
//    request.setValue("\(request.HTTPBody?.length)", forHTTPHeaderField: "Content-Length")
    
    return request
}

func uploadFileToAWSS3(#filePath: String, #dataForm: JSONDictionary){

    let policy = dataForm["policy"] as! [String: AnyObject]
    let conditions = policy["conditions"] as! [[String: AnyObject]]
    let signature = dataForm["signature"] as! String
    let policyEncoded = dataForm["encoded_policy"] as! String
    let url = dataForm["url"] as! String
    
    var key = ""
    var acl = ""
    var algorithm = ""
    var credential = ""
    var date = ""

    
    for dict in conditions {
        let keyString = dict.keys.first!
        switch keyString{
        case "key":
            key = dict.values.first as! String
        case "acl":
            acl = dict.values.first as! String
        case "x-amz-algorithm":
            algorithm = dict.values.first as! String
        case "x-amz-credential":
            credential = dict.values.first as! String
        case "x-amz-date":
            date = dict.values.first as! String
        default:
            break
        }
    }

    let param = [
        "key"  : key,
        "acl"    : acl,
        "X-Amz-Algorithm": algorithm,
        "X-Amz-Signature": signature,
        "X-Amz-Date": date,
        "X-Amz-Credential": credential,
        "Policy": policyEncoded
    ]
    
//    var request = createRequest(url:NSURL(string: url)!, filePath:filePath , key: key, acl: acl, algorithm: algorithm, signature: signature, date: date, credential: credential, policy: policyEncoded)
    let filename = filePath.lastPathComponent
    let mimetype = mimeTypeForPath(filePath)
    
//    YepAWSService.uploadFiletoAWS(filePath, filename:  filename, mimetype: mimetype,withKey:key, acl: acl, algorithm: algorithm, signature: signature, date: date, credential: credential, policy: policyEncoded)

    let request = AFHTTPRequestSerializer().multipartFormRequestWithMethod("POST", URLString: url, parameters: param, constructingBodyWithBlock: { formData  in
        
        formData.appendPartWithFileURL(NSURL(fileURLWithPath: filePath)!, name: "file", fileName: filename, mimeType: mimetype, error: nil)
        
    }, error: nil)
    
    let manager = AFURLSessionManager(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration())
    manager.responseSerializer = AFXMLParserResponseSerializer()
//    var progress = NSProgress()

    var uploadTask = manager.uploadTaskWithStreamedRequest(request, progress: nil, completionHandler: { (response, responseObject, error) in
        
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
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}


/// Create body of the multipart/form-data request
///
/// :param: parameters   The optional dictionary containing keys and values to be passed to web service
/// :param: filePathKey  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
/// :param: paths        The optional array of file paths of the files to be uploaded
/// :param: boundary     The multipart/form-data boundary
///
/// :returns:            The NSData of the body of the request

func createBodyWithParameters(#parameters: [[String: String]]?, #filePathKey: String?, #paths: [String]?, #boundary: String) -> NSData {
    let body = NSMutableData()
    
    if parameters != nil {
        for dict in parameters! {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(dict.keys.first!)\"\r\n\r\n")
            body.appendString("\(dict.values.first!)\r\n")
        }
    }
    
    if paths != nil {
        for path in paths! {
            let filename = path.lastPathComponent
            let data = NSData(contentsOfFile: path)
            let mimetype = mimeTypeForPath(path)
            
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
            body.appendString("Content-Type: \(mimetype)\r\n\r\n")
            body.appendData(data!)
            body.appendString("\r\n")
        }
    }
    
    body.appendString("--\(boundary)--\r\n")
    return body
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

func requestAWSS3UploadForm(#failureHandler: ((Reason, String?) -> ())?, #completion: JSONDictionary -> Void) {
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/api/v1/attachments/s3_upload_public_form_fields", method: .GET, requestParameters:[:], parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}
