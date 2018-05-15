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
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // handle Return in the text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        // color the login button
        loginButton.backgroundColor = AppSettings.themeBackgroundColor
        loginButton.tintColor = AppSettings.themeForegroundColor
        loginButton.layer.cornerRadius = 8
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
    @IBAction func loginPressed(_ sender: Any) {
        statusLabel.text = ""
        guard
            usernameField.hasText,
            passwordField.hasText,
            let username = usernameField.text,
            let password = passwordField.text else
        {
            return
        }
        LoginController(username: username, password: password).login { account, resp in

            if resp.failed {
                self.statusLabel.text = "Error: \n" + (resp.error?.localizedDescription)!
            }
            if account.authtoken != nil {
                AppSettings.account = account
                self.performSegue(withIdentifier: "ShowMainSegue", sender: nil)
            }
        }

    }
}

