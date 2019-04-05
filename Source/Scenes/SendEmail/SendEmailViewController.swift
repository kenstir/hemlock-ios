//
//  SendEmailViewController.swift
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

import UIKit
import MessageUI

class SendEmailViewController: UIViewController {
    
    //MARK: - Properties
    
    var sent = false
    var to: String?
    var subject: String?
    var body: String?
    var log: String?

    @IBOutlet weak var sendEmailButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Functions
    
    func setupViews() {
        Style.styleButton(asOutline: sendEmailButton)
        sendEmailButton.addTarget(self, action: #selector(sendEmailButtonPressed(sender:)), for: .touchUpInside)
        
        messageLabel.text = ""
        messageLabel.sizeToFit()

        self.setupHomeButton()
    }
    
    @objc func sendEmailButtonPressed(sender: Any) {
        guard let to = self.to,
            let subject = self.subject,
            let body = self.body else
        {
            showAlert(title: "Internal Error", error: HemlockError.shouldNotHappen("No email parameters"))
            return
        }
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([to])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            if let data = log?.data(using: .utf8) {
                mail.addAttachmentData(data, mimeType: "text/plain", fileName: "network.log")
            }

            mail.navigationBar.tintColor = App.theme.barTextForegroundColor

            present(mail, animated: true)
        } else {
            messageLabel.text = "Can't send email"
            showAlert(title: "Can't send email", message: "This device is not configured to send email.\n\nPlease manually send this report to \(to)")
        }
    }
}

//MARK: - MFMailComposeViewControllerDelegate
extension SendEmailViewController: MFMailComposeViewControllerDelegate {
    private func resultString(_ result: MFMailComposeResult) -> String {
        switch result {
        case .cancelled: return "Cancelled"
        case .failed: return "Sending failed"
        case .saved: return "Not sent, draft saved"
        case .sent: return "Sent, thank you!"
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        messageLabel.text = resultString(result)
        self.sendEmailButton.isEnabled = (result != .sent)
        controller.dismiss(animated: true)
    }
}
