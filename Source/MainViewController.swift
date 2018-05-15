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
    
    var buttons: [(String, String?)] = [
        ("Search", nil),
        ("Items Checked Out", "ShowItemsCheckedOutSegue"),
        ("Holds", nil),
        ("Fines", nil),
        ("My Lists", nil)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData()
    }
    
    func setupData() {
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MainTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MainTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let tuple = buttons[indexPath.row]
        if let button = cell.button as? MainButton {
            button.setTitle(tuple.0, for: .normal)
            if let segue = tuple.1 {
                button.segue = segue
                button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            }
        }
        
        return cell
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        if let button = sender as? MainButton,
            let segue = button.segue
        {
            self.performSegue(withIdentifier: segue, sender: nil)
        }
    }
}
