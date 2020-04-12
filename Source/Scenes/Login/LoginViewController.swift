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

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var activitySemaphore = 0 // stop spinning when 0
    
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
        let (savedUsername, savedPassword) = LoginController.getSavedLoginCredentials()
        if let _ = savedUsername, let _ = savedPassword {
            doLogin()
        }
    }

    func setupViews() {
        // restore saved username/password
        let (savedUsername, savedPassword) = LoginController.getSavedLoginCredentials();
        usernameField.text = savedUsername
        passwordField.text = savedPassword

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
        self.activitySemaphore += 1
        activityIndicator.startAnimating()
    }
    
    func maybeStopSpinning() {
        self.activitySemaphore -= 1
        if self.activitySemaphore == 0 {
            self.activityIndicator.stopAnimating()
        }
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
        let account = Account(username, password: password)

        self.startSpinning()

        LoginController(for: account).login { resp in

            if resp.failed {
                self.showAlert(title: "Login failed", message: resp.errorMessage)
                self.maybeStopSpinning()
                return
            }
            self.maybeStopSpinning()

            if account.authtoken != nil {
                self.getSession(account)
            }
        }
    }
    
    func getSession(_ account: Account) {
        self.startSpinning()
        
        LoginController.getSession(account) { resp in

            if resp.failed {
                self.showAlert(title: "Failed to initialize session", message: resp.errorMessage)
                self.maybeStopSpinning()
                return
            }

            self.maybeStopSpinning()

            account.userID = resp.obj?.getInt("id")
            account.homeOrgID = resp.obj?.getInt("home_ou")
            account.dayPhone = resp.obj?.getString("day_phone")
            App.account = account
            LoginController.saveLoginCredentials(account: account)

            self.performSegue(withIdentifier: "ShowMainSegue", sender: nil)
        }
    }
}
