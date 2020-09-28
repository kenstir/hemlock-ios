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
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var initWithCredential: Credential? = nil
    var didCompleteFetch = false
    
    /// prevent LoginVC from attempting auto-login as it is being destructed during account switching
    var alreadyLoggedIn = false

    override func viewDidLoad() {
        os_log("login creds:%x:%d: VC viewDidLoad", self, didCompleteFetch)
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        os_log("login creds:%x:%d: VC viewWillAppear", self, didCompleteFetch)
        super.viewWillAppear(animated)

        self.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        os_log("login creds:%x:%d: VC viewDidAppear", self, didCompleteFetch)
        super.viewDidAppear(animated)
        
        // auto login
        if let credential = Utils.coalesce(initWithCredential, App.credentialManager.lastUsedCredential) {
            usernameField.text = credential.username
            passwordField.text = credential.password
            doLogin()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        os_log("login creds:%x:%d: VC viewWillDisappear", self, didCompleteFetch)
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        os_log("login creds:%x:%d: VC viewDidDisappear", self, didCompleteFetch)
        super.viewDidDisappear(animated)
    }

    func setupViews() {
        os_log("login creds:%x:%d: VC setupViews", self, didCompleteFetch)

        // handle Return in the text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        // add style
        loginButton.isEnabled = false
        Style.styleButton(asInverse: loginButton)
        Style.styleButton(asPlain: forgotPasswordButton)
        Style.styleActivityIndicator(activityIndicator)
        
        self.setupTapToDismissKeyboard(onScrollView: scrollView)
        self.scrollView.setupKeyboardAutoResizer()
    }

    func fetchData() {
        self.activityIndicator.startAnimating()
        ActorService.fetchServerVersion().then { (resp: GatewayResponse) -> Promise<Void> in
            if let versionString = resp.str {
                Gateway.serverVersionString = versionString
            }
            return App.fetchIDL()
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
            UIApplication.shared.open(url, options: [:])
        }
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
        os_log("login creds:%x:%d: VC doLogin username=%@", self, didCompleteFetch, username)

        activityIndicator.startAnimating()

        let credential = Credential(username: username, password: password)
        let account = Account(username, password: password)
        AuthService.fetchAuthToken(credential: credential).then { (authtoken: String) -> Promise<(OSRFObject)> in
            account.authtoken = authtoken
            return AuthService.fetchSession(authtoken: authtoken)
        }.done { obj in
            account.loadSession(fromObject: obj)
            self.saveAccountAndFinish(account: account)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func saveAccountAndFinish(account: Account) {
        alreadyLoggedIn = true
        App.account = account
        App.credentialManager.add(credential: Credential(username: account.username, password: account.password))
        self.performSegue(withIdentifier: "ShowMainSegue", sender: nil)
    }
}
