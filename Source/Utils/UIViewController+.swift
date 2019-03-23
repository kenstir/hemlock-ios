//
//  UIViewController+.swift
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

extension UIViewController {
    //MARK: - common view setup

    func addActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        return activityIndicator
    }

    func setupHomeButton() {
        let homeButton = UIBarButtonItem(image: UIImage(named: "Home"), style: .plain, target: self, action: #selector(popToRootVC(sender:)))
        self.navigationItem.rightBarButtonItem = homeButton
    }

    @objc func popToRootVC(sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    /// Set up a tap recognizer on a scrollView that dismisses the keyboard
    func setupTapToDismissKeyboard(onScrollView scrollView: UIScrollView) {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        recognizer.numberOfTapsRequired = 1
        recognizer.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(recognizer)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            dismissKeyboard()
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    //MARK: - showAlert
    
    func showAlert(title: String, message: String, isError: Bool = false) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        Style.styleAlertController(alertController)
        if isError && MFMailComposeViewController.canSendMail() {
            alertController.addAction(UIAlertAction(title: "Send bug report", style: .destructive) { action in
                guard let initialVC = UIStoryboard(name: "SendEmail", bundle: nil).instantiateInitialViewController(),
                    let vc = initialVC as? SendEmailViewController else { return }
                vc.to = "kenstir.apps@gmail.com" //TODO: take from app config
                vc.subject = "[Hemlock] report from \(Bundle.appName) \(Bundle.appVersion)"
                vc.body = "error:\n\n" + message + "\n\nlog:\n\n" + Analytics.getLog()
                self.navigationController?.pushViewController(vc, animated: true)
            })
        }
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true)
    }
    
    func showAlert(error: Error, title: String) {
        showAlert(title: title, message: error.localizedDescription, isError: true)
    }
    
    //MARK: - Handling session expired errors
    
    /// handle error in a promise chain by presenting the appropriate alert
    func presentGatewayAlert(forError error: Error, title: String = "Error") {
        if isSessionExpired(error: error) {
            App.unloadIDL()
            self.showSessionExpiredAlert(error, relogHandler: {
                self.popToLogin()
            })
        } else {
            self.showAlert(error: error, title: title)
        }
    }

    func showSessionExpiredAlert(_ error: Error, relogHandler: (() -> Void)?, cancelHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Session timed out", message: "Do you want to login again?", preferredStyle: .alert)
        Style.styleAlertController(alertController)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            if let h = cancelHandler { h() }
        }
        let loginAction = UIAlertAction(title: "Login Again", style: .default) { action in
            if let h = relogHandler { h() }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(loginAction)
        self.present(alertController, animated: true)
    }
    
    /// reset the VC stack to the Login VC (the initial VC on the Main storyboard)
    func popToLogin() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        UIApplication.shared.keyWindow?.rootViewController = vc
    }
}
