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
    
    func hoursOfOperation(obj: OSRFObject?, day: Int) -> String? {
        guard let openApiStr = obj?.getString("dow_\(day)_open"),
            let closeApiStr = obj?.getString("dow_\(day)_close") else { return nil }
        if openApiStr == closeApiStr {
            return "closed"
        }
        if let openDate = OSRFObject.apiHoursFormatter.date(from: openApiStr),
            let closeDate = OSRFObject.apiHoursFormatter.date(from: closeApiStr)
        {
            let openStr = OSRFObject.outputHoursFormatter.string(from: openDate)
            let closeStr = OSRFObject.outputHoursFormatter.string(from: closeDate)
            return "\(openStr) - \(closeStr)"
        }
        return nil
    }
    
    func onHoursLoaded(_ obj: OSRFObject?) {
        day0Hours.text = hoursOfOperation(obj: obj, day: 0)
        day1Hours.text = hoursOfOperation(obj: obj, day: 1)
        day2Hours.text = hoursOfOperation(obj: obj, day: 2)
        day3Hours.text = hoursOfOperation(obj: obj, day: 3)
        day4Hours.text = hoursOfOperation(obj: obj, day: 4)
        day5Hours.text = hoursOfOperation(obj: obj, day: 5)
        day6Hours.text = hoursOfOperation(obj: obj, day: 6)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "orgChooserCell", for: indexPath)
        let org = Organization.find(byId: orgID)
        cell.textLabel?.text = org?.name
        return cell
    }
}

//MARK: - UITableViewDelegate
extension OrgDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        //let entry = tableView.
        vc.title = "Library"
        vc.options = orgLabels
        vc.selectionChangedHandler = { value in
            self.orgID = Organization.find(byName: value)?.id
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
