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
    @IBOutlet weak var day0Hours: UILabel!
    @IBOutlet weak var day1Hours: UILabel!
    @IBOutlet weak var day2Hours: UILabel!
    @IBOutlet weak var day3Hours: UILabel!
    @IBOutlet weak var day4Hours: UILabel!
    @IBOutlet weak var day5Hours: UILabel!
    @IBOutlet weak var day6Hours: UILabel!
    @IBOutlet weak var emailAddress: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    var orgID: Int? = App.account?.homeOrgID

    var orgLabels: [String] = []
    var didCompleteFetch = false
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // deselect row when navigating back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        //if !didCompleteFetch {
            fetchData()
        //}
    }
    
    //MARK: - Functions
    
    func fetchData() {
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTreeAndSettings(forOrgID: orgID))
        
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        firstly {
            when(fulfilled: promises)
        }.done {
            //self.didCompleteFetch = true
            self.fetchHours()
            self.onOrgsLoaded()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchHours() {
        guard let authtoken = App.account?.authtoken,
            let orgID = self.orgID else { return }
        
        ActorService.fetchOrgUnitHours(authtoken: authtoken, forOrgID: orgID).done { obj in
            self.onHoursLoaded(obj)
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error)
        }
    }

    func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self

        setupActivityIndicator()
        self.setupHomeButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func onHoursLoaded(_ obj: OSRFObject?) {
        if let open = obj?.getString("dow_0_open"), let close = obj?.getString("dow_0_close") { day0Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_1_open"), let close = obj?.getString("dow_1_close") { day1Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_2_open"), let close = obj?.getString("dow_2_close") { day2Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_3_open"), let close = obj?.getString("dow_3_close") { day3Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_4_open"), let close = obj?.getString("dow_4_close") { day4Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_5_open"), let close = obj?.getString("dow_5_close") { day5Hours.text = "\(open) - \(close)" }
        if let open = obj?.getString("dow_6_open"), let close = obj?.getString("dow_6_close") { day6Hours.text = "\(open) - \(close)" }
    }
    
    // init that can't happen until fetchData completes
    func onOrgsLoaded() {
        tableView.reloadData()
        loadOrgData()
    }

    func loadOrgData() {
        orgLabels = Organization.getSpinnerLabels()
        let org = Organization.find(byId: orgID)
        emailAddress.text = org?.email
        phoneNumber.text = org?.phoneNumber
/*
        var selectOrgIndex = 0
        let defaultOrgID = App.account?.homeOrgID
        for index in 0..<Organization.visibleOrgs.count {
            let org = Organization.visibleOrgs[index]
            if org.id == defaultOrgID {
                selectOrgIndex = index
            }
        }
        
        selectedOrgName = orgLabels[selectOrgIndex].trim()
        self.org = Organization.find(byName: selectedOrgName)
        setupTitle()
 */
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
        //let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let cell = tableView.dequeueReusableCell(withIdentifier: "orgChooserCell", for: indexPath)
        //cell.textLabel?.text = "Location"
        //cell.detailTextLabel?.text = org?.name
        let org = Organization.find(byId: orgID)
        cell.textLabel?.text = org?.name
        //cell.detailTextLabel?.text = ""
        return cell
    }
}

//MARK: - UITableViewDelegate
extension OrgDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        //let entry = tableView.
        vc.title = "Library"
        //vc.selectedOption = ??
        vc.options = orgLabels
        vc.selectionChangedHandler = { value in
//            entry.value = value
            self.orgID = Organization.find(byName: value.trim())?.id
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
