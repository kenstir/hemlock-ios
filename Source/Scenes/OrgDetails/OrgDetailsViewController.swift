//
//  OrgDetailsViewController.swift
//
//  Copyright (C) 2020 Kenneth H. Cox
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
import PromiseKit
import PMKAlamofire

class OrgDetailsViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    
    weak var activityIndicator: UIActivityIndicatorView!

    var orgLabels: [String] = []
    var didCompleteFetch = false
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !didCompleteFetch {
            fetchData()
        }
    }
    
    //MARK: - Functions
    
    func fetchData() {
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTree())
        
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
        }.done {
            self.didCompleteFetch = true
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func setupViews() {
        setupActivityIndicator()
        self.setupHomeButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
}

//MARK: - UITableViewDataSource
extension OrgDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Location"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "orgChooserCell", for: indexPath)
        cell.textLabel?.text = "Location"
        //cell.detailTextLabel?.text = ""
        return cell
    }
}

//MARK: - UITableViewDelegate
extension OrgDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        let entry = options[indexPath.row]
        vc.title = entry.label
        vc.selectedOption = entry.value
        switch indexPath.row {
        case searchClassIndex:
            vc.options = scopes
        case searchFormatIndex:
            vc.options = formatLabels
        case searchLocationIndex:
            vc.options = orgLabels
            vc.optionIsPrimary = Organization.getIsPrimary()
        default:
            break
        }

        vc.selectionChangedHandler = { value in
            entry.value = value
            self.optionsTable.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
 */
    }
}
