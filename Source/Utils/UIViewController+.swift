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
import PromiseKit
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
//        os_log("centerSubview: ---", log: Utils.log, type: .info)
//        os_log("centerSubview: view.frame=%.0fx%.0f", log: Utils.log, type: .info, view.frame.width, view.frame.height)
//        os_log("centerSubview: subv.frame=%.0fx%.0f", log: Utils.log, type: .info, subview.frame.width, subview.frame.height)
//        os_log("centerSubview: view.center=[%.0f,%.0f]", log: Utils.log, type: .info, view.center.x, view.center.y)
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

    /// reset the VC stack to the Login VC
    func popToLogin(forAddingCredential: Bool = false) {
        guard let vc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() else { return }
        if let loginNav = vc as? UINavigationController,
        let loginVC = loginNav.topViewController as? LoginViewController {
            loginVC.isAddingAccount = forAddingCredential
        }
        swapRootVC(vc, duration: 0.5)
    }

    /// reset the VC stack to the Main VC
    func popToMain() {
        let name = App.config.enableMainGridScene ? "MainGrid" : "Main"
        guard let vc = UIStoryboard(name: name, bundle: nil).instantiateInitialViewController() else { return }
        swapRootVC(vc)
    }

    // adapted with gratitude from https://stackoverflow.com/questions/41144523/swap-rootviewcontroller-with-animation
    func swapRootVC(_ vc: UIViewController, duration: TimeInterval = 0.75, completion: ((Bool) -> Void)? = nil) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        // Calling "UIView.transition" below will animate the swap.
        window.rootViewController = vc

        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: .transitionCrossDissolve, animations: {}, completion: completion)
    }

    /// push the VC from the named Storyboard
    func pushVC(fromStoryboard name: String) {
        if let vc = UIStoryboard(name: name, bundle: nil).instantiateInitialViewController() {
            self.navigationController?.pushViewController(vc, animated: true)
        }
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

    //MARK: - Error Handling
    
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
        guard let vc = UIStoryboard(name: "SendEmail", bundle: nil).instantiateInitialViewController() as? SendEmailViewController else { return }
        vc.to = App.config.bugReportEmailAddress
        vc.subject = "[Hemlock] error report - \(Bundle.appName) \(Bundle.appVersion)"
        vc.body = "app: \(Bundle.appName)\n"
            + "version: \(Bundle.appVersion)\n"
            + "error: " + errorMessage
        vc.log = Analytics.getLog()
        self.navigationController?.pushViewController(vc, animated: true)
    }

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
    
    func presentGatewayAlert(forResults results: [PromiseKit.Result<Void>]) {
        var errors: [Error] = []
        for result in results {
            switch result {
            case .fulfilled: //(let value):
                break
            case .rejected(let error):
                errors.append(error)
            }
        }
        if let error = errors.last,
            isSessionExpired(error: error) {
            self.presentGatewayAlert(forError: error)
        } else {
            // 2020-09-28 don't present the error; it was an error loading metadata
            // for checkouts or holds, e.g. record is deleted, and the OPAC doesn't
            // display such errors either
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

    //MARK: - Helper Functions

    /// helper function to ensure I don't forget to copy a new image to the app-specific asset bundle
    func loadAssetImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil && Bundle.isTestFlightOrDebug {
            showAlert(title: "Missing Image", message: "App is missing image \"\(named)\"")
        }
        return image
    }

    /// open URL
    func launchURL(url: String) {
        if let u = URL(string: url) {
            UIApplication.shared.open(u)
        }
    }
}
