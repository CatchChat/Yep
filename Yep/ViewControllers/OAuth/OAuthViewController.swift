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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.whiteColor()
        
        animatedOnNavigationBar = false

        title = socialAccount.name
        
        var accessToken = ""
        
        if let token = YepUserDefaults.v1AccessToken.value {
            accessToken = token
        }
        
        let request = NSURLRequest(URL: NSURL(string: "\(socialAccount.authURL)?_tkn=\(accessToken)")!)
        
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

        println(request.URL?.description)
        
        if let newURLString = request.URL?.description {
            handleWithRequestURL(newURLString)
        }

        return true
    }
    
    private func handleWithRequestURL(url: String) {

      if url.contains("/auth/success") {
        
            socialAccountWithProvider(socialAccount.rawValue, failureHandler: { reason, errorMessage in
                
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }

            }, completion: { provider in
                println(provider)

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    if let strongSelf = self {
                        strongSelf.dismissViewControllerAnimated(true) {
                            strongSelf.afterOAuthAction?(socialAccount: strongSelf.socialAccount)
                        }
                    }
                }
            })
            
        } else if url.contains("/auth/failure") {
//            println(url)
        
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

