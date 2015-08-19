//
//  OAuthViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import OnePasswordExtension

class OAuthViewController: BaseViewController, UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    var socialAccount: SocialAccount!
    var afterOAuthAction: ((socialAccount: SocialAccount) -> Void)?

    @IBOutlet weak var onePasswordButton: UIBarButtonItem!
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var authenticated = false
    
    var failedRequest: NSURLRequest!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        animatedOnNavigationBar = false

        title = NSLocalizedString("OAuth", comment: "")
        
        let request = authURLRequestWithURL(socialAccount.authURL)
        
        webView.loadRequest(request)
        
        webView.delegate = self

        webViewDidStartLoad(webView)
        
        if !OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            println("User dosent have one password")
        }
    }

    @IBAction func fillPassword(sender: AnyObject) {
        OnePasswordExtension.sharedExtension().fillLoginIntoWebView(webView, forViewController: self, sender: sender) { (finish, error) -> Void in
            
        }
    }
    // MARK: Actions

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UIWebViewDelegate

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let result = authenticated
        
        println(request.URL?.description)
        
        if let newURLString = request.URL?.description {
            handleWithRequestURL(newURLString)

        }

        if (!authenticated) {
            failedRequest = request
            NSURLConnection(request: request, delegate: self)
        }

        return result
    }
    
    func handleWithRequestURL(url: String) {

      if url.contains("/auth/success") {
        
            self.dismissViewControllerAnimated(true, completion: nil)
            
            socialAccountWithProvider(self.socialAccount.description.lowercaseString, failureHandler: { (reason, errorMessage) -> Void in
                
                defaultFailureHandler(reason, errorMessage)
                
            }, completion: { [weak self] provider in
                println(provider)

                if let strongSelf = self {
                    strongSelf.afterOAuthAction?(socialAccount: strongSelf.socialAccount)
                }
            })
            
        } else if url.contains("/auth/failure") {
            self.webViewDidFinishLoad(self.webView)
            
            YepAlert.alertSorry(message: NSLocalizedString("OAuth Error", comment: ""), inViewController: self, withDismissAction: { () -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    

    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        activityIndicator.startAnimating()
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        activityIndicator.stopAnimating()
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
