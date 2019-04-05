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
import os.log

extension UIViewController {

    //MARK: - common view setup

    func addActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        view.addSubview(activityIndicator)
        centerSubview(activityIndicator)

        return activityIndicator
    }

    func centerSubview(_ subview: UIView) {
        os_log("centerSubview: ---", log: Utils.log, type: .info)
        os_log("centerSubview: view.frame=%.0fx%.0f", log: Utils.log, type: .info, view.frame.width, view.frame.height)
        os_log("centerSubview: subv.frame=%.0fx%.0f", log: Utils.log, type: .info, subview.frame.width, subview.frame.height)
        os_log("centerSubview: view.center=[%.0f,%.0f]", log: Utils.log, type: .info, view.center.x, view.center.y)
//        os_log("centerSubview: subv.center=[%f,%f]", log: Utils.log, type: .info, subview.center.x, subview.center.y)
        subview.center = view.center
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
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        Style.styleAlertController(alertController)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true)
    }

    func showAlert(title: String, error: Error) {
        let message = error.localizedDescription
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        Style.styleAlertController(alertController)
        if Bundle.isTestFlightOrDebug && MFMailComposeViewController.canSendMail() {
            alertController.addAction(UIAlertAction(title: "Send report to developer", style: .destructive) { action in
                self.sendErrorReport(errorMessage: message)
            })
        }
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true)
    }
    
    private func sendErrorReport(errorMessage: String) {
        guard let initialVC = UIStoryboard(name: "SendEmail", bundle: nil).instantiateInitialViewController(),
            let vc = initialVC as? SendEmailViewController else { return }
        vc.to = App.config.bugReportEmailAddress
        vc.subject = "[Hemlock] error report - \(Bundle.appName) \(Bundle.appVersion)"
        vc.body = "app: \(Bundle.appName)\n"
            + "version: \(Bundle.appVersion)\n"
            + "error: " + errorMessage
        vc.log = Analytics.getLog()
        self.navigationController?.pushViewController(vc, animated: true)
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
            self.showAlert(title: title, error: error)
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
