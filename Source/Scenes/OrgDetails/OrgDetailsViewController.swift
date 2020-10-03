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
    @IBOutlet weak var hoursHeader: UILabel!
    @IBOutlet weak var day0Stack: UIStackView!
    @IBOutlet weak var day0Hours: UILabel!
    @IBOutlet weak var day1Stack: UIStackView!
    @IBOutlet weak var day1Hours: UILabel!
    @IBOutlet weak var day2Stack: UIStackView!
    @IBOutlet weak var day2Hours: UILabel!
    @IBOutlet weak var day3Stack: UIStackView!
    @IBOutlet weak var day3Hours: UILabel!
    @IBOutlet weak var day4Stack: UIStackView!
    @IBOutlet weak var day4Hours: UILabel!
    @IBOutlet weak var day5Stack: UIStackView!
    @IBOutlet weak var day5Hours: UILabel!
    @IBOutlet weak var day6Stack: UIStackView!
    @IBOutlet weak var day6Hours: UILabel!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var addressLine1: UILabel!
    @IBOutlet weak var addressLine2: UILabel!

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
            self.fetchOrgDetails()
            self.fetchHours()
            self.fetchAddress()
            self.onOrgsLoaded()
        }.ensure {
            self.enableButtonsWhenReady()
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchOrgDetails() {
        guard let orgID = self.orgID else { return }
        ActorService.fetchOrg(forOrgID: orgID).ensure {
            print("stop heree")
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchHours() {
        guard let authtoken = App.account?.authtoken,
            let orgID = self.orgID else { return }
        
        ActorService.fetchOrgUnitHours(authtoken: authtoken, forOrgID: orgID).done { obj in
            self.onHoursLoaded(obj)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchAddress() {
        guard let org = Organization.find(byId: orgID),
            let addressID = org.addressID else { return }
        
        ActorService.fetchOrgAddress(addressID: addressID).done { obj in
            self.onAddressLoaded(obj)
//        }.ensure {
//            self.enableButtonsWhenReady()
//            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self

        setupActivityIndicator()
        self.setupHomeButton()
        self.setupActionButtons()
        self.setupHoursViews()
    }
    
    func setupActionButtons() {
        Style.styleButton(asPlain: webSiteButton)
        Style.styleButton(asPlain: mapButton)
        Style.styleButton(asPlain: emailButton)
        Style.styleButton(asPlain: phoneButton)
        webSiteButton.addTarget(self, action: #selector(webSiteButtonPressed(sender:)), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(mapButtonPressed(sender:)), for: .touchUpInside)
        emailButton.addTarget(self, action: #selector(emailButtonPressed(sender:)), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneButtonPressed(sender:)), for: .touchUpInside)
        enableButtonsWhenReady()
    }
    
    func setupHoursViews() {
        if !App.config.enableHoursOfOperation {
            hoursHeader?.isHidden = true
            day0Stack?.isHidden = true
            day1Stack?.isHidden = true
            day2Stack?.isHidden = true
            day3Stack?.isHidden = true
            day4Stack?.isHidden = true
            day5Stack?.isHidden = true
            day6Stack?.isHidden = true
        }
    }

    func enableButtonsWhenReady() {
        let org = Organization.find(byId: orgID)
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
        if let obj = org?.addressObj, let _ = mapsURL(obj) {
            mapButton.isEnabled = true
        } else {
            mapButton.isEnabled = false
        }
    }
    
    @objc func webSiteButtonPressed(sender: UIButton) {
        let org = Organization.find(byId: orgID)
        guard let infoURL = org?.infoURL,
            let url = URL(string: infoURL) else { return }
        let canOpen = UIApplication.shared.canOpenURL(url)
        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
    }
    
    @objc func mapButtonPressed(sender: UIButton) {
        let org = Organization.find(byId: orgID)
        guard let addressObj = org?.addressObj,
            let url = mapsURL(addressObj) else { return }
//        let canOpen = UIApplication.shared.canOpenURL(url)
//        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
    }

    @objc func emailButtonPressed(sender: UIButton) {
        let org = Organization.find(byId: orgID)
        guard let email = org?.email,
            let url = URL(string: "mailto:\(email)") else { return }
//        let canOpen = UIApplication.shared.canOpenURL(url)
//        print("canOpen: \(canOpen)")
        UIApplication.shared.open(url)
    }
    
    @objc func phoneButtonPressed(sender: UIButton) {
        let org = Organization.find(byId: orgID)
        guard let number = org?.phoneNumber,
            let url = URL(string: "tel:\(number)") else { return }
//        let canOpen = UIApplication.shared.canOpenURL(url)
//        print("canOpen: \(canOpen)")
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
    
    func getAddressLine1(_ obj: OSRFObject) -> String {
        var line1 = ""
        if let s = obj.getString("street1") {
            line1.append(contentsOf: s)
        }
        if let s = obj.getString("street2"), !s.isEmpty {
            line1.append(contentsOf: " ")
            line1.append(contentsOf: s)
        }
        return line1
    }
    
    func getAddressLine2(_ obj: OSRFObject) -> String {
        var line2 = ""
        if let s = obj.getString("city"), !s.isEmpty {
            line2.append(contentsOf: s)
        }
        if let s = obj.getString("state"), !s.isEmpty {
            line2.append(contentsOf: ", ")
            line2.append(contentsOf: s)
        }
        if let s = obj.getString("post_code"), !s.isEmpty {
            line2.append(contentsOf: " ")
            line2.append(contentsOf: s)
        }
        return line2
    }
    
    func mapsURL(_ obj: OSRFObject) -> URL? {
        var addr = getAddressLine1(obj)
        addr.append(contentsOf: " ")
        addr.append(contentsOf: getAddressLine2(obj))
        guard var c = URLComponents(string: "https://maps.apple.com/") else { return nil }
        c.queryItems = [URLQueryItem(name: "q", value: addr)]
        return c.url
    }

    func onAddressLoaded(_ aoaObj: OSRFObject?) {
        let org = Organization.find(byId: orgID)
        org?.addressObj = aoaObj
        guard let obj = aoaObj else { return }

        addressLine1.text = getAddressLine1(obj)
        addressLine2.text = getAddressLine2(obj)
    }

    func onOrgsLoaded() {
        tableView.reloadData()

        orgLabels = Organization.getSpinnerLabels()
        //org = Organization.find(byId: orgID)
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
        guard orgLabels.count > 0 else { return }
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        //let entry = tableView.
        vc.title = "Library"
        vc.options = orgLabels
        vc.selectionChangedHandler = { value in
            let org = Organization.find(byName: value)
            self.orgID = org?.id
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
