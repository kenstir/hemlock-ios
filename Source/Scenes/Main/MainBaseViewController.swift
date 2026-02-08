/*
 *  Copyright (C) 2024 Kenneth H. Cox
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import UIKit
import os.log

class MainBaseViewController: UIViewController {
    private let log = OSLog(subsystem: Bundle.appIdentifier, category: "Main")
    private var didShowSystemAlert = false
    private var systemAlertPending = false

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
#if USE_FCM
        registerForRuntimeNotifications()
        let didHandleNotification = handleLaunchNotification()
#else
        let didHandleNotification = false
#endif
        systemAlertPending = !didHandleNotification && App.serviceConfig.consortiumService.alertBanner != nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // cause func to be called when returning to app, e.g. from browser
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard systemAlertPending && !didShowSystemAlert else { return }
        systemAlertPending = false
        didShowSystemAlert = true
        DispatchQueue.main.async { self.showSystemAlert() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    //MARK: - Callback Functions

    @objc func applicationDidBecomeActive() {
        fatalError("must override")
    }

    @objc func accountButtonPressed(sender: UIBarButtonItem) {
        let haveMultipleAccounts = App.credentialManager.credentials.count > 1

        // Create an action sheet to present the account options
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)

        // Add an action for each stored account
        if haveMultipleAccounts {
            for credential in App.credentialManager.credentials {
                let action = UIAlertAction(title: credential.chooserLabel, style: .default) { action in
                    self.doSwitchAccount(toAccount: credential)
                }
                var imageName = "Account"
                if credential.username == App.account?.username {
                    action.isEnabled = false
                    imageName = "Account with Checkmark"
                }
                if let icon = loadAssetImage(named: imageName) {
                    action.setValue(icon, forKey: "image")
                }
                alertController.addAction(action)
            }
        }

        // Add remaining actions
        alertController.addAction(UIAlertAction(title: "Add account", style: .default) { action in
            self.doAddAccount()
        })
        alertController.addAction(UIAlertAction(title: "Logout", style: .destructive) { action in
            self.doLogout()
        })
        if haveMultipleAccounts {
            alertController.addAction(UIAlertAction(title: "Clear All Accounts", style: .destructive) { action in
                self.clearAllAccounts()
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        self.present(alertController, animated: true)
    }

    func doSwitchAccount(toAccount storedAccount: Credential) {
        App.switchCredential(credential: storedAccount)
        self.popToLogin()
    }

    func doAddAccount() {
        App.switchCredential(credential: nil)
        self.popToLogin(forAddingCredential: true)
    }

    func doLogout() {
        App.logout()
        self.popToLogin()
    }

    func clearAllAccounts() {
        // confirm action
        let alertController = UIAlertController(title: "Clear all accounts?", message: "Logout and clear all accounts from this device?  This will not delete your library account.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Clear all accounts", style: .destructive) { action in
            self.doLogoutAndClearAll()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true)
    }

    func doLogoutAndClearAll() {
        App.logout()
        App.credentialManager.clearAllCredentials()
        self.popToLogin()
    }

    func showSystemAlert() {
        guard let msg = App.serviceConfig.consortiumService.alertBanner else { return }
        let alertController = UIAlertController(title: "System Alert", message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertController, animated: true)

        // TODO: handle ipad popoverController
    }
}
