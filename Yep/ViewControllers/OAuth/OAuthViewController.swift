//
//  OAuthViewController.swift
//  Yep
//
//  Created by kevinzhow on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import WebViewJavascriptBridge

class OAuthViewController: UIViewController {
    
    var webView: UIWebView!
    
    var bridge: WebViewJavascriptBridge!
    
    var socialAccount: SocialAccount!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = UIWebView(frame: view.bounds)
        view.addSubview(webView)
        
        bridge = WebViewJavascriptBridge(forWebView: webView, handler: { data, responseCallback in
            println("Got response")
        })
        
        var request = authURLRequestWithURL(socialAccount.authURL)
        println(socialAccount.authURL.absoluteString)
        webView.loadRequest(request)
        // Do any additional setup after loading the view.
    }

}
