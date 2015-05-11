//
//  OAuthViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import WebViewJavascriptBridge

class OAuthViewController: UIViewController, UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var webView: UIWebView!
    
    var bridge: WebViewJavascriptBridge!
    
    var socialAccount: SocialAccount!
    
    var authenticated = false
    
    var failedRequest: NSURLRequest!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = UIWebView(frame: view.bounds)

        view.addSubview(webView)
        
        var request = authURLRequestWithURL(socialAccount.authURL)
        
        webView.loadRequest(request)
        
        bridge = WebViewJavascriptBridge(forWebView: webView, webViewDelegate: self, handler: { data, responseCallback in
            if let status = data as? [String: Bool],
                let success = status["success"] {
                    
                    if success {
                        
                        self.dismissViewControllerAnimated(true, completion: nil)
                        
                        socialAccountWithProvider(self.socialAccount.description.lowercaseString, failureHandler: { (reason, errorMessage) -> Void in
                            
                            defaultFailureHandler(reason, errorMessage)
                            
                        }, completion: { provider in
                                
                            println(provider)
                                
                        })
                        
                    } else {
                        println("OAuth Error")
                    }
                    
            } else {
                println("Bridge Error")
            }
        
        })
        
        // Do any additional setup after loading the view.
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var result = authenticated;
        if (!authenticated) {
            failedRequest = request
            NSURLConnection(request: request, delegate: self)
        }
        return result;
    }
    
    func connection(connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            var baseURL = authURLRequestWithURL(socialAccount.authURL)
            
            if challenge.protectionSpace.host == baseURL.URL!.host {
                println("trusting connection to host \(challenge.protectionSpace.host)")
                
                var credential = NSURLCredential(trust: challenge.protectionSpace.serverTrust)
                
                challenge.sender.useCredential(credential, forAuthenticationChallenge: challenge)
            }
        }
        
        challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge)
    }

    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        println("Did recieve response")
        authenticated = true
        connection.cancel()
        webView.loadRequest(failedRequest)
    }
}
