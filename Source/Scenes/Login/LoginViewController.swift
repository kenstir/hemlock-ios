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
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        // restore saved username/password
        let (savedUsername, savedPassword) = LoginController.getSavedLoginCredentials();
        usernameField.text = savedUsername
        passwordField.text = savedPassword

        // handle Return in the text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        // style the buttons
        Style.styleButton(asInverse: loginButton)
        Style.styleButton(asPlain: forgotPasswordButton)
        
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }

    //MARK: Actions

    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        if let url = URL(string: (App.library?.url)! + ("/eg/opac/password_reset") ) {
            UIApplication.shared.open(url, options: [:])
        }
        //App.library?.url + "/eg/opac/password_reset"
    }
    @IBAction func loginPressed(_ sender: Any) {
        guard
            usernameField.hasText,
            passwordField.hasText,
            let username = usernameField.text,
            let password = passwordField.text else
        {
            return
        }
        let account = Account(username, password: password)

        activityIndicator.startAnimating()

        LoginController(for: account).login { resp in

            if resp.failed {
                self.showAlert(title: "Login failed", message: resp.errorMessage)
                self.activityIndicator.stopAnimating()
                return
            }

            if account.authtoken != nil {
                self.getSession(account)
            }
        }
    }
    
    func getSession(_ account: Account) {
        LoginController.getSession(account) { resp in

            if resp.failed {
                self.showAlert(title: "Failed to initialize session", message: resp.errorMessage)
                self.activityIndicator.stopAnimating()
                return
            }

            self.activityIndicator.stopAnimating()

            account.userID = resp.obj?.getInt("id")
            App.account = account
            LoginController.saveLoginCredentials(account: account)

            self.performSegue(withIdentifier: "ShowMainSegue", sender: nil)
        }
    }
}
