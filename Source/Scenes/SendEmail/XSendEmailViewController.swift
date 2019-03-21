//
//  XSendLogViewController.swift
//  X is for teXture
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import AsyncDisplayKit
import MessageUI

class XSendEmailViewController: ASViewController<ASTextNode> {
    
    //MARK: - Properties
    
    var to: String?
    var body: String?
    
    //MARK: - Lifecycle
    
    init() {
        super.init(node: ASTextNode())
        self.title = "Send Email"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendEmail()
    }
    
    //MARK: - Setup
    
    func setupNodes() {
        node.backgroundColor = UIColor.white
        node.attributedText = Style.makeTitleString("Send bug report to the developer")
    }
    
    //MARK: - Functions
    
    func sendEmail() {
        guard let to = self.to, let body = self.body else {
            showAlert(title: "Internal Error", message: "No email parameters")
            return
        }
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([to])
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            showAlert(title: "Can't send email", message: "This device is not configured to send email.\n\nPlease manually send this report to \(to)")
        }
    }
    
}

//MARK: - MFMailComposeViewControllerDelegate
extension XSendEmailViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
