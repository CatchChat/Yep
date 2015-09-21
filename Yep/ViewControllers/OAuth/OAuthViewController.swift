//
//  OAuthViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import OnePasswordExtension

class OAuthViewController: BaseViewController {

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
            println("NOT 1Password")
        }
    }

    // MARK: Actions

    @IBAction func fillPassword(sender: AnyObject) {
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(webView, forViewController: self, sender: sender, showOnlyLogins: false) { (finish, error) -> Void in
            
        }
    }

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UIWebViewDelegate

extension OAuthViewController: UIWebViewDelegate {

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let result = authenticated
        
        println(request.URL?.description)
        
        if let newURLString = request.URL?.description {
            handleWithRequestURL(newURLString)

        }

        if (!authenticated) {
            failedRequest = request
            //NSURLConnection(request: request, delegate: self)
        }

        return result
    }
    
    private func handleWithRequestURL(url: String) {

      if url.contains("/auth/success") {
        
            socialAccountWithProvider(self.socialAccount.description.lowercaseString, failureHandler: { reason, errorMessage in
                
                defaultFailureHandler(reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }

            }, completion: { provider in
                println(provider)

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    if let strongSelf = self {
                        strongSelf.afterOAuthAction?(socialAccount: strongSelf.socialAccount)

                        strongSelf.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            })
            
        } else if url.contains("/auth/failure") {
            webViewDidFinishLoad(webView)
            
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
}

// MARK: NSURLConnectionDelegate

extension OAuthViewController: NSURLConnectionDelegate {

    func connection(connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {

            let authURL = socialAccount.authURL
            
            if challenge.protectionSpace.host == authURL.host, let trust = challenge.protectionSpace.serverTrust {

                println("OAuthViewController trusting connection to host \(challenge.protectionSpace.host)")
                
                let credential = NSURLCredential(trust: trust)
                
                challenge.sender?.useCredential(credential, forAuthenticationChallenge: challenge)
            }
        }
        
        challenge.sender?.continueWithoutCredentialForAuthenticationChallenge(challenge)
    }
}

// MARK: NSURLConnectionDataDelegate

extension OAuthViewController: NSURLConnectionDataDelegate {

    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {

        println("OAuthViewController didReceiveResponse")

        authenticated = true
        
        connection.cancel()

        webView.loadRequest(failedRequest)
    }
}

