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
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    var orgID: Int? = App.account?.homeOrgID

    var org: Organization? = nil
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

        fetchData()
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
        self.setupActionButtons()
    }
    
    func setupActionButtons() {
        Style.styleButton(asPlain: webSiteButton)
        Style.styleButton(asPlain: emailButton)
        Style.styleButton(asPlain: phoneButton)
        webSiteButton.addTarget(self, action: #selector(webSiteButtonPressed(sender:)), for: .touchUpInside)
        emailButton.addTarget(self, action: #selector(emailButtonPressed(sender:)), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneButtonPressed(sender:)), for: .touchUpInside)
        enableButtonsWhenReady()
    }

    func enableButtonsWhenReady() {
        if let infoURL = org?.infoURL, !infoURL.isEmpty {
            webSiteButton.isEnabled = true
        } else {
            webSiteButton.isEnabled = false
        }
        if let email = org?.email, !email.isEmpty {
            emailButton.isEnabled = true
            emailButton.setTitle(email, for: .normal)
        } else {
            emailButton.isEnabled = false
            emailButton.setTitle(nil, for: .normal)
        }
        if let number = org?.phoneNumber, !number.isEmpty {
            phoneButton.isEnabled = true
            phoneButton.setTitle(number, for: .normal)
        } else {
            phoneButton.isEnabled = false
            phoneButton.setTitle(nil, for: .normal)
        }
    }
    
    @objc func webSiteButtonPressed(sender: UIButton) {
        guard let infoURL = org?.infoURL,
            let url = URL(string: infoURL) else { return }
        let canOpen = UIApplication.shared.canOpenURL(url)
        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
    }
    
    @objc func emailButtonPressed(sender: UIButton) {
        guard let email = org?.email,
            let url = URL(string: "mailto:\(email)") else { return }
        let canOpen = UIApplication.shared.canOpenURL(url)
        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
    }
    
    @objc func phoneButtonPressed(sender: UIButton) {
        guard let number = org?.phoneNumber,
            let url = URL(string: "tel:\(number)") else { return }
        let canOpen = UIApplication.shared.canOpenURL(url)
        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
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

        orgLabels = Organization.getSpinnerLabels()
        org = Organization.find(byId: orgID)
        self.enableButtonsWhenReady()
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
        cell.textLabel?.text = org?.name
        return cell
    }
}

//MARK: - UITableViewDelegate
extension OrgDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard orgLabels.count > 0 else { return }
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        //let entry = tableView.
        vc.title = "Library"
        vc.options = orgLabels
        vc.selectionChangedHandler = { value in
            self.org = Organization.find(byName: value)
            self.orgID = self.org?.id
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
