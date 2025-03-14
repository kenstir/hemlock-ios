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

    @IBOutlet weak var orgButton: UIButton!
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
    @IBOutlet weak var closuresStack: UIStackView!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var webSiteButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var addressLine1: UILabel!
    @IBOutlet weak var addressLine2: UILabel!

    weak var activityIndicator: UIActivityIndicatorView!

    var orgID: Int? = App.account?.homeOrgID

    var orgLabels: [String] = []

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
            self.fetchOrg()
            self.fetchHours()
            self.fetchClosures()
            self.fetchAddress()
            self.onOrgTreeLoaded()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchOrg() {
        // fetch details for this org again, so it's up-to-date
        // and not the cached version from the orgTree
        guard let orgID = self.orgID else { return }
        ActorService.fetchOrg(forOrgID: orgID).done {
            self.onOrgLoaded()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchHours() {
        guard let authtoken = App.account?.authtoken,
            let orgID = self.orgID else { return }
        
        ActorService.fetchOrgHours(authtoken: authtoken, forOrgID: orgID).done { obj in
            self.onHoursLoaded(obj)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func fetchClosures() {
        guard let authtoken = App.account?.authtoken,
            let orgID = self.orgID else { return }

        ActorService.fetchOrgClosures(authtoken: authtoken, forOrgID: orgID).done { objList in
            self.onClosuresLoaded(objList)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func fetchAddress() {
        guard let org = Organization.find(byId: orgID),
            let addressID = org.addressID else { return }
        
        ActorService.fetchOrgAddress(addressID: addressID).done { obj in
            self.onAddressLoaded(obj)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func setupViews() {
        setupActivityIndicator()
        self.setupHomeButton()
        self.setupActionButtons()
        self.setupHoursViews()
    }
    
    func setupActionButtons() {
        Style.styleButton(asOutline: orgButton)
        Style.styleButton(asPlain: webSiteButton)
        Style.styleButton(asPlain: mapButton)
        Style.styleButton(asPlain: emailButton)
        Style.styleButton(asPlain: phoneButton)
        orgButton.addTarget(self, action: #selector(orgButtonPressed(sender:)), for: .touchUpInside)
        webSiteButton.addTarget(self, action: #selector(webSiteButtonPressed(sender:)), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(mapButtonPressed(sender:)), for: .touchUpInside)
        emailButton.addTarget(self, action: #selector(emailButtonPressed(sender:)), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneButtonPressed(sender:)), for: .touchUpInside)
        orgButton.isEnabled = false
        webSiteButton.isEnabled = false
        emailButton.isEnabled = false
        phoneButton.isEnabled = false
        mapButton.isEnabled = false
    }
    
    func setupHoursViews() {
        if App.config.enableHoursOfOperation {
            hoursHeader?.text = R.getString("Hours")
        } else {
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

    func onOrgLoaded() {
        let org = Organization.find(byId: orgID)
        if let name = org?.name {
            orgButton.isEnabled = true
            orgButton.setTitle(name, for: .normal)
        } else {
            orgButton.isEnabled = false
        }
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

    func onAddressLoaded() {
        let org = Organization.find(byId: orgID)
        if let obj = org?.addressObj, let _ = mapsURL(obj) {
            mapButton.isEnabled = true
        } else {
            mapButton.isEnabled = false
        }
    }
    
    @objc func orgButtonPressed(sender: UIButton) {
         guard orgLabels.count > 0 else { return }
         guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
         
         vc.title = "Library"
         vc.optionLabels = orgLabels
         vc.selectionChangedHandler = { index, _ in
             let org = Organization.visibleOrgs[index]
             self.orgID = org.id
         }

         self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func webSiteButtonPressed(sender: UIButton) {
        let org = Organization.find(byId: orgID)
        guard let infoURL = org?.infoURL,
            let url = URL(string: infoURL) else { return }
//        let canOpen = UIApplication.shared.canOpenURL(url)
//        print("canOpen: \(canOpen)")
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

    func onClosuresLoaded(_ objs: [OSRFObject]) {
        let now = Date()
        var upcomingClosures: [OSRFObject] = []
        for obj in objs {
            if let date = obj.getDate("close_end"), date > now && upcomingClosures.count < App.config.upcomingClosuresLimit {
                upcomingClosures.append(obj)
            }
        }
        addClosureRows(upcomingClosures)
    }

    func addClosureRows(_ closures: [OSRFObject]) {
        // clear all existing rows
        while let view = closuresStack.arrangedSubviews.first {
            view.removeFromSuperview()
        }

        // add message if none
        if closures.isEmpty {
            closuresStack.addArrangedSubview(makeClosureRow(firstString: "No closures scheduled"))
            return
        }

        // find out if any closures have date ranges; if so we need extra room
        let anyClosuresWithDateRange = closures.contains {
            let isMultiDay = $0.getBoolOrFalse("multi_day")
            let isFullDay = $0.getBoolOrFalse("full_day")
            return isMultiDay || !isFullDay
        }

        // add a row per closure
        for closure in closures {
            closuresStack.addArrangedSubview(makeClosureRow(closure, useWideDateColumn: anyClosuresWithDateRange))
        }
    }

    func makeClosureRow(_ closure: OSRFObject, useWideDateColumn wide: Bool) -> UIView {

        let dateLabel = getClosureDateLabel(closure)
        let reason = closure.getString("reason") ?? nil
        return makeClosureRow(firstString: dateLabel, secondString: reason, useWideDateColumn: wide)
    }

    func makeClosureRow(firstString: String, secondString: String? = nil, useWideDateColumn wide: Bool = false) -> UIView {

        // create hstack to hold row
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.fill
        stackView.alignment = UIStackView.Alignment.top
        stackView.spacing = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // add leading space
        let spacerLabel = UILabel()
        spacerLabel.widthAnchor.constraint(equalToConstant: 16.0).isActive = true
        stackView.addArrangedSubview(spacerLabel)

        // add first label
        let firstLabel = UILabel()
        firstLabel.text = firstString
        stackView.addArrangedSubview(firstLabel)

        if secondString != nil {
            // set constraints on first label only if we have a second
            let width = (wide) ? 0.45 : 0.28
            firstLabel.numberOfLines = (wide) ? 2 : 1
            firstLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: width).isActive = true

            // add second label
            let secondLabel = UILabel()
            //secondLabel.backgroundColor = UIColor.lightGray // hack to visualize layout
            secondLabel.text = secondString
            secondLabel.numberOfLines = (wide) ? 2 : 1
            stackView.addArrangedSubview(secondLabel)
        }

        return stackView
    }

    func getClosureDateLabel(_ closure: OSRFObject) -> String {
        guard let startDate = closure.getDate("close_start"),
              let endDate = closure.getDate("close_end") else {
            return "???"
        }
        let isFullDay = closure.getBoolOrFalse("full_day")
        let isMultiDay = closure.getBoolOrFalse("multi_day")
        if isMultiDay {
            let start = OSRFObject.outputDayOnlyFormatter.string(from: startDate)
            let end = OSRFObject.outputDayOnlyFormatter.string(from: endDate)
            return "\(start) - \(end)"
        } else if isFullDay {
            return OSRFObject.outputDayOnlyFormatter.string(from: startDate)
        } else {
            let start = OSRFObject.getDateTimeLabel(from: startDate)
            let end = OSRFObject.getDateTimeLabel(from: endDate)
            return "\(start) - \(end)"
        }
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

    func onOrgTreeLoaded() {
        orgLabels = Organization.getSpinnerLabels()
    }
}
