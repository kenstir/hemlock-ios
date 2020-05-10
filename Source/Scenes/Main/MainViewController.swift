//
//  MainViewController.swift
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

import Foundation
import UIKit

class MainViewController: UIViewController {
    
    //MARK: - fields

    @IBOutlet weak var accountButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bottomButtonBar: UIStackView!
    @IBOutlet weak var fullCatalogButton: UIButton!
    @IBOutlet weak var libraryLocatorButton: UIButton!

    var buttons: [(String, String, (() -> UIViewController)?)] = []
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // deselect row when navigating back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func setupButtons() {
        buttons = [
            ("Search", "ShowSearchSegue", nil),
            ("Items Checked Out", "ShowCheckoutsSegue", nil),
            //        ("Items Checked Out", "", XCheckoutsViewController.self),
            ("Holds", "ShowHoldsSegue", nil),
            ("Fines", "ShowFinesSegue", nil),
        ]
        if App.config.barcodeFormat != .Disabled {
            buttons.append(("Show Card", "ShowCardSegue", nil))
        }
    }

    func setupViews() {
        navigationItem.title = App.config.title
        tableView.dataSource = self
        tableView.delegate = self
        accountButton.target = self
        accountButton.action = #selector(accountButtonPressed(sender:))
        Style.styleBarButton(accountButton)
        if App.config.enableMainSceneBottomToolbar {
            Style.styleButton(asPlain: fullCatalogButton)
            Style.styleButton(asPlain: libraryLocatorButton)
        } else {
            bottomButtonBar.isHidden = true
            fullCatalogButton.isHidden = true
            libraryLocatorButton.isHidden = true
        }
    }
    
    @IBAction func accountButtonPressed(sender: UIButton) {
        // Show an actionSheet to present the links
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        alertController.addAction(UIAlertAction(title: "Add account", style: .default) { action in
            //self.doAddAccount
        })
        alertController.addAction(UIAlertAction(title: "Logout", style: .default) { action in
            self.doLogout()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popoverController = alertController.popoverPresentationController {
            let view: UIView = self.view
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        self.present(alertController, animated: true)
    }
    
    func doLogout() {
        LoginController.clearLoginCredentials(account: App.account)
        App.unloadIDL()
        self.popToLogin()
    }
    
    func doAddAccount() {
        
    }

    @IBAction func fullCatalogButtonPressed(_ sender: Any) {
        //open catalog url
        if let baseurl = App.library?.url,
            let url = URL(string: baseurl) {
             UIApplication.shared.open(url)
        }
    }
    
    @IBAction func libraryLocatorButtonPressed(_ sender: Any) {
        //open library location url
        let urlbase = "http://pines.georgialibraries.org/pinesLocator/locator.html"
        if let url = URL(string: urlbase) {
            UIApplication.shared.open(url)
        }
    }
}

//MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return App.account?.username
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MainTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MainTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let tuple = buttons[indexPath.row]
        let label = tuple.0
        let segue = tuple.1
        
        var image: UIImage?
        if App.config.haveColorButtonImages {
            image = UIImage(named: label)?.withRenderingMode(.automatic)
            //cell.imageView?.image = image
        } else {
            image = UIImage(named: label)?.withRenderingMode(.alwaysTemplate)
            //cell.imageView?.image = image
            cell.tintColor = App.theme.primaryColor
        }
        cell.imageView?.image = image
        cell.textLabel?.text = App.behavior.getCustomString(label) ?? label

        cell.title = label
        cell.segue = segue
        
        return cell
    }
}

//MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tuple = buttons[indexPath.row]
        let segue = tuple.1
        if let vcfunc = tuple.2 {
            let vc = vcfunc()
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.performSegue(withIdentifier: segue, sender: nil)
        }
    }
}
