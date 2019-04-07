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

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bottomButtonBar: UIStackView!
    @IBOutlet weak var fullCatalogButton: UIButton!
    @IBOutlet weak var libraryLocatorButton: UIButton!

    var buttons: [(String, String, UIViewController.Type?)] = []
    
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
        if Bundle.isDebug {
            //buttons.append(("My Lists", "ShowListsSegue", nil))
            buttons.append(("Holds", "", XPlaceHoldViewController.self))
        }
    }

    func setupViews() {
        navigationItem.title = App.config.title
        tableView.dataSource = self
        tableView.delegate = self
        logoutButton.target = self
        logoutButton.action = #selector(logoutPressed(sender:))
        Style.styleBarButton(logoutButton)
        if App.config.enableMainSceneBottomToolbar {
            Style.styleButton(asPlain: fullCatalogButton)
            Style.styleButton(asPlain: libraryLocatorButton)
        } else {
            bottomButtonBar.isHidden = true
            fullCatalogButton.isHidden = true
            libraryLocatorButton.isHidden = true
        }
    }
    
    @IBAction func logoutPressed(sender: UIButton) {
        LoginController.clearLoginCredentials(account: App.account)
        App.unloadIDL()
        self.performSegue(withIdentifier: "ShowLoginSegue", sender: nil)
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
        
        let image = UIImage(named: label)?.withRenderingMode(.alwaysTemplate)
        
        cell.tintColor = App.theme.primaryColor
        cell.imageView?.image = image
        cell.textLabel?.text = label
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
        if let vctype = tuple.2 {
            let vc = vctype.init()
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.performSegue(withIdentifier: segue, sender: nil)
        }
    }
}
