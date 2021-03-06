//
//  LoadingViewController.swift
//  RemitaPaymentGateway
//
//  Created by Diagboya Iyare on 30/08/2020.
//  Copyright © 2020 Systemspecs Nig. Ltd. All rights reserved.

import UIKit
import WebKit

class LoadingViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    var paymentRequest: PaymentRequest!
    var delegate: RemitaPaymentGatewayDelegate!
    
    var url: String = ""
    var publicKey: String = ""
    var rrr: String = ""
    
override func viewDidLoad()
{
   super.viewDidLoad()
 
  let htmlString: String = """
    <!DOCTYPE html>
    <html lang="en">
    <header><meta name="viewport" content="initial-scale=1.0" /></header>
    <body  onload="makePayment()">
    <script>
    function makePayment() {
    var paymentEngine = RmPaymentEngine.init({key:'\(publicKey)',
    processRrr: true,
    extendedData:{
    customFields: [
    {
    name:"rrr",
    value:'\(rrr)'
    }
    ]
    },
    onSuccess: function (response) {
    console.log(JSON.stringify(response));
    },
    onError: function (response) {
    console.log(JSON.stringify(response));
    },
    onClose: function () {
    console.log("onClose");
    },
    });
    paymentEngine.openIframe();
    }
    </script>
    <script type="text/javascript" src="\(url)/payment/v1/remita-pay-inline.bundle.js"\\> </script>
    </body>
    </html>
"""
    let urlBase = URL(string: url)!

    webView.loadHTMLString(htmlString, baseURL: urlBase)
}

    
public override func loadView() {
 
    let wkWebViewConfig = WKWebViewConfiguration()
    
    let source = """
     function captureLog(msg) {
     window.webkit.messageHandlers.iosListener.postMessage(msg);
    }
    window.console.log = captureLog;
    
    """

    let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

    wkWebViewConfig.userContentController.addUserScript(script)
    wkWebViewConfig.userContentController.add(self, name: "iosListener")
    webView = WKWebView(frame: .zero, configuration: wkWebViewConfig)
    webView.contentMode = .scaleToFill
    webView.uiDelegate = self
    view = webView

    self.url = paymentRequest.url
    self.publicKey = paymentRequest.key
    self.rrr = paymentRequest.rrr
    
    delegate = clientDelegate
 }
    
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
 {
    let response = "\(message.body)"
  
    if response.contains("paymentReference") && response.contains("transactionId")
    {
        var paymentResponse = PaymentResponse()
        
        let jsonData =  response.data(using: .utf8)!
        
        let responseData = try! JSONDecoder().decode(PaymentResponseData.self,from: jsonData)
        
        if case responseData.paymentReference = responseData.paymentReference, !responseData.paymentReference.isEmpty {
            
            paymentResponse.responseCode = Constants.SUCCESS_CODE.rawValue
            paymentResponse.responseMessage = Constants.SUCCESS_MESSAGE.rawValue
            paymentResponse.paymentResponseData = responseData
            
            delegate.onPaymentCompleted(paymentResponse: paymentResponse)
            
        } else {
            
            paymentResponse.responseCode = Constants.FAILED_CODE.rawValue
            paymentResponse.responseMessage = Constants.FAILED_MESSAGE.rawValue
            paymentResponse.paymentResponseData = responseData
            
            delegate.onPaymentFailed(paymentResponse: paymentResponse)
        }
    }
    
    if response.contains("onClose")
    {
        self.close()
    }
}
 
override open var shouldAutorotate: Bool {
        return false
   }

override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
   }
}


