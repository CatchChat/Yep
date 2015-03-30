//
//  YepStorageService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/30.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

/// Create request
///
/// :param: userid   The userid to be passed to web service
/// :param: password The password to be passed to web service
/// :param: email    The email address to be passed to web service
///
/// :returns:         The NSURLRequest that was created

func createRequest(#url:NSURL, #filePath: String, #key: String, #acl: String, #algorithm: String, #signature: String, #date: String, #credential: String, #policy: String) -> NSURLRequest {
    let param = [
        "key"  : key,
        "acl"    : acl,
        "X-Amz-Algorithm": algorithm,
        "X-Amz-Signature": signature,
        "X-Amz-Date": date,
        "X-Amz-Credential": credential,
        "Policy": policy,
    ]  // build your dictionary however appropriate
    
    let boundary = generateBoundaryString()
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", paths: [filePath], boundary: boundary)
    
    return request
}

func uploadFileToAWSS3(#filePath: String, #dataForm: JSONDictionary) -> String {

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
    var bucket = ""

    
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

    
    var request = createRequest(url:NSURL(string: url)!, filePath:filePath , key: key, acl: acl, algorithm: algorithm, signature: signature, date: date, credential: credential, policy: policyEncoded)
    
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
        data, response, error in
        
        if error != nil {
            // handle error here
            return
        }
        
        // if response was JSON, then parse it
        
        var parseError: NSError?
        let responseObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &parseError)
        
        if let responseDictionary = responseObject as? NSDictionary {
            // handle the parsed dictionary here
            println("did upload \(responseDictionary)")
        } else {
            println("upload error")
            // handle parsing error here
        }
        
        // if response was text or html, then just convert it to a string
        //
        // let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
        // println("responseString = \(responseString)")
        
        // note, if you want to update the UI, make sure to dispatch that to the main queue, e.g.:
        //
        // dispatch_async(dispatch_get_main_queue()) {
        //     // update your UI and model objects here
        // }
    })
    task.resume()
    return ""
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
