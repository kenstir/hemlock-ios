//
//  OptionsViewController.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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

class OptionsViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var table: UITableView!
    
    var optionLabels: [String] = []
    var optionIsEnabled: [Bool] = []
    var optionIsPrimary: [Bool] = []
    var optionValues: [String] = []
    var selectedPath: IndexPath?
    var selectedLabel: String?
    var selectionChangedHandler: ((_ row: Int, _ label: String) -> Void)?

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Functions
    
    func setupViews() {
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView() // prevent ghost rows at end of table
        self.updateCheckmarks()
    }
    
    func updateCheckmarks() {
        guard let paths = table?.indexPathsForVisibleRows else { return }
        
        for indexPath in paths {
            guard let cell = table.cellForRow(at: indexPath) else { continue }
            updateViewCell(forCell: cell, indexPath: indexPath)
        }
    }
    
    func updateViewCell(forCell cell: UITableViewCell, indexPath: IndexPath) {
        if indexPath == selectedPath {
            cell.accessoryType = .checkmark
        } else if cell.textLabel?.text?.trim() == selectedLabel {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        if optionIsEnabled.count > indexPath.row {
            cell.textLabel?.isEnabled = optionIsEnabled[indexPath.row]
            cell.isUserInteractionEnabled = optionIsEnabled[indexPath.row]
        }
        if optionIsPrimary.count > indexPath.row {
            cell.textLabel?.font = optionIsPrimary[indexPath.row]
                ? UIFont.boldSystemFont(ofSize: 19.0)
                : UIFont.systemFont(ofSize: 17.0)
        }
    }
}

extension OptionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionLabels.count
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return ""
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath)
        
        cell.textLabel?.text = optionLabels[indexPath.row]
        updateViewCell(forCell: cell, indexPath: indexPath)
        
        return cell
    }
}

extension OptionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trimmedLabel = optionLabels[indexPath.row].trim()
        selectedLabel = trimmedLabel
        selectedPath = indexPath
        updateCheckmarks()
        tableView.deselectRow(at: indexPath, animated: true)
        selectionChangedHandler?(indexPath.row, trimmedLabel)

        // navigate back after short delay for user to perceive the update
        let delay = 0.200
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
