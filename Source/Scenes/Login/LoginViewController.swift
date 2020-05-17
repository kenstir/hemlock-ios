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

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // auto login
        if App.credentialManager.lastAccount != nil {
            doLogin()
        }
    }

    func setupViews() {
        // restore last credentials used
        if let lastAccount = App.credentialManager.lastAccount {
            usernameField.text = lastAccount.username
            passwordField.text = lastAccount.password
        }

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
        fetchIDL() {
            self.loginButton.isEnabled = true
        }
    }
    
    func startSpinning() {
        activityIndicator.startAnimating()
    }
    
    func maybeStopSpinning() {
        self.activityIndicator.stopAnimating()
    }
    
    func fetchIDL(completion: @escaping () -> Void) {
        self.startSpinning()
        
        App.fetchIDL().catch { error in
            self.showAlert(title: "Error", error: error)
        }.finally {
            self.maybeStopSpinning()
            completion()
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
        if App.idlLoaded ?? false {
            doLogin()
        } else {
            fetchIDL() {
                if App.idlLoaded ?? false {
                    self.doLogin()
                }
            }
        }
    }
    
    func doLogin() {
        guard
            usernameField.hasText,
            passwordField.hasText,
            let username = usernameField.text,
            let password = passwordField.text else
        {
            return
        }

        self.startSpinning()

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
            self.maybeStopSpinning()
        }
    }
    
    func saveAccountAndFinish(account: Account) {
        App.account = account
        App.credentialManager.add(credential: Credential(username: account.username, password: account.password))
        self.performSegue(withIdentifier: "ShowMainSegue", sender: nil)
    }
}
