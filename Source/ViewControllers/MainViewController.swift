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

struct MainViewButtonData {
    let title: String
    let segue: String
    init(_ title: String, _ segue: String) {
        self.title = title
        self.segue = segue
    }
}

class MainViewController: UITableViewController {
    
    //MARK: - fields
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet var table: UITableView!
    
    var buttons: [(String, String)] = [
        ("Search", "ShowSearchSegue"),
        ("Items Checked Out", "ShowCheckoutsSegue"),
        ("Holds", "ShowHoldsSegue"),
        ("Fines", "ShowFinesSegue"),
        ("My Lists", "ShowMyListsSegue")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoutButton.target = self
        logoutButton.action = #selector(logoutPressed(sender:))
    }

    // MARK: - UITableViewController
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AppSettings.account?.username
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MainTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MainTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let tuple = buttons[indexPath.row]
        let label = tuple.0
        let segue = tuple.1
        
        cell.cellImage.image = UIImage(named: label)
        cell.cellLabel.text = label
        cell.title = label
        cell.segue = segue

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tuple = buttons[indexPath.row]
        let segue = tuple.1
        self.performSegue(withIdentifier: segue, sender: nil)
    }
    
    @IBAction func logoutPressed(sender: UIButton) {
        AppSettings.account?.logout()
        self.performSegue(withIdentifier: "ShowLoginSegue", sender: nil)
    }
}
