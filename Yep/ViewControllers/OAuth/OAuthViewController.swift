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

    var socialAccount: SocialAccount!

    @IBOutlet weak var webView: UIWebView!

    var bridge: WebViewJavascriptBridge!
    
    var authenticated = false
    
    var failedRequest: NSURLRequest!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("OAuth", comment: "")
        
        let request = authURLRequestWithURL(socialAccount.authURL)
        
        webView.loadRequest(request)
        
        bridge = WebViewJavascriptBridge(forWebView: webView, webViewDelegate: self, handler: { data, responseCallback in

            if let status = data as? [String: Bool], let success = status["success"] {

                if success {

                    self.dismissViewControllerAnimated(true, completion: nil)

                    socialAccountWithProvider(self.socialAccount.description.lowercaseString, failureHandler: { (reason, errorMessage) -> Void in

                        defaultFailureHandler(reason, errorMessage)

                    }, completion: { provider in
                        println(provider)
                        // TODO: 解析 socialAccount Provider
                    })

                } else {
                    println("OAuth Error")
                }

            } else {
                println("Bridge Error")
            }
        })
    }

    // MARK: Actions

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UIWebViewDelegate

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let result = authenticated

        if (!authenticated) {
            failedRequest = request
            NSURLConnection(request: request, delegate: self)
        }

        return result
    }

    // MARK: NSURLConnectionDelegate

    func connection(connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            let authURL = socialAccount.authURL
            
            if challenge.protectionSpace.host == authURL.host {
                println("trusting connection to host \(challenge.protectionSpace.host)")
                
                var credential = NSURLCredential(trust: challenge.protectionSpace.serverTrust)
                
                challenge.sender.useCredential(credential, forAuthenticationChallenge: challenge)
            }
        }
        
        challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge)
    }

    // MARK: NSURLConnectionDataDelegate

    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        println("Did recieve response")

        authenticated = true
        
        connection.cancel()

        webView.loadRequest(failedRequest)
    }
}
