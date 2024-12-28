//
//  LoginViewController.swift
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

import PromiseKit
import PMKAlamofire
import UIKit
import os.log

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var didCompleteFetch = false

    /// This is a secondary Login to support the "Add Account" action
    var isAddingAccount = false

    /// prevent LoginVC from attempting auto-login as it is being destructed during account switching
    var alreadyLoggedIn = false

    override func viewDidLoad() {
        os_log("login: viewDidLoad:   adding=%d last=%@", isAddingAccount, App.credentialManager.lastUsedCredential?.username ?? "(nil)")
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        os_log("login: viewDidAppear: adding=%d last=%@", isAddingAccount, App.credentialManager.lastUsedCredential?.username ?? "(nil)")
        super.viewDidAppear(animated)

        // auto login
        if !isAddingAccount,
           let credential = App.credentialManager.lastUsedCredential
        {
            usernameField.text = credential.username
            passwordField.text = credential.password
            doLogin()
        }
    }

    func setupViews() {
        // handle Return in the text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        // add style
        loginButton.isEnabled = false
        Style.styleButton(asInverse: loginButton)
        Style.styleButton(asPlain: cancelButton)
        Style.styleButton(asPlain: forgotPasswordButton)
        Style.styleActivityIndicator(activityIndicator)

        if isAddingAccount {
            cancelButton.isHidden = false
        } else {
            cancelButton.isHidden = true
            cancelButton.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }

        self.setupTapToDismissKeyboard(onScrollView: scrollView)
        self.scrollView.setupKeyboardAutoResizer()
    }

    func fetchData() {
        self.activityIndicator.startAnimating()

        // the cache keys need to be available before we make any other requests that depend on them
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchServerVersion())
        promises.append(ActorService.fetchServerCacheKey())

        firstly {
            when(fulfilled: promises)
        }.then {
            // IDL needs to be loaded before we can fetchOrgTree, which returns an OSRF-encoded object
            return App.fetchIDL()
        }.then {
            return ActorService.fetchOrgTree()
        }.done {
            self.loginButton.isEnabled = true
            self.didCompleteFetch = true
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }

    //MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameField {
            self.passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if App.idlLoaded ?? false {
                doLogin()
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }

    //MARK: Actions

    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        if let baseurl_string = App.library?.url,
            let baseurl = URL(string: baseurl_string) {
            let url: URL = baseurl.appendingPathComponent("/eg/opac/password_reset")
            UIApplication.shared.open(url)
        }
    }

    @IBAction func cancelPressed(_ sender: Any) {
        self.popToLogin()
    }

    @IBAction func loginPressed(_ sender: Any) {
        doLogin()
    }
    
    func doLogin() {
        if alreadyLoggedIn {
            return
        }
        guard
            usernameField.hasText,
            passwordField.hasText,
            let username = usernameField.text,
            let password = passwordField.text else
        {
            return
        }
        os_log("login: doLogin: username=%@", username)

        activityIndicator.startAnimating()

        var credential = Credential(username: username, password: password)
        let account = Account(username, password: password)
        AuthService.fetchAuthToken(credential: credential).then { (authtoken: String) -> Promise<(OSRFObject)> in
            account.authtoken = authtoken
            return AuthService.fetchSession(authtoken: authtoken)
        }.then { (obj: OSRFObject) -> Promise<Void> in
            account.loadSession(fromObject: obj)
            return ActorService.fetchUserSettings(account: account)
        }.done {
            credential.displayName = account.displayName
            self.onSuccessfulLogin(account: account, credential: credential)
        }.catch { error in
            self.logFailedLogin(error)
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }

    func onSuccessfulLogin(account: Account, credential: Credential) {
        alreadyLoggedIn = true
        App.account = account
        App.credentialManager.add(credential: credential)
        logSuccessfulLogin(account: account, numCredentials: App.credentialManager.numCredentials)
        self.popToMain()
    }

    func logSuccessfulLogin(account: Account, numCredentials: Int) {
        let homeOrg = Organization.find(byId: account.homeOrgID)
        let parentOrg = Organization.find(byId: homeOrg?.parent)
        Analytics.setUserProperty(value: homeOrg?.shortname, forName: Analytics.UserProperty.homeOrg)
        Analytics.setUserProperty(value: parentOrg?.shortname, forName: Analytics.UserProperty.parentOrg)
        Analytics.logEvent(event: Analytics.Event.login, parameters: [
            Analytics.Param.result: Analytics.Value.ok,
            Analytics.Param.numAccounts: numCredentials
        ])
    }

    func logFailedLogin(_ error: Error) {
        let message = error.localizedDescription
        Analytics.logEvent(event: Analytics.Event.login, parameters: [
            Analytics.Param.result: message
        ])
    }
}
