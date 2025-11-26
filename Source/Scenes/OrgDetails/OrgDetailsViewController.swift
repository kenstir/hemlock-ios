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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import UIKit

class OrgDetailsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var orgButton: UIButton!
    @IBOutlet weak var hoursHeader: UILabel!
    @IBOutlet weak var day0Stack: UIStackView!
    @IBOutlet weak var day0Hours: UILabel!
    @IBOutlet weak var day0Note: UILabel!
    @IBOutlet weak var day1Stack: UIStackView!
    @IBOutlet weak var day1Hours: UILabel!
    @IBOutlet weak var day1Note: UILabel!
    @IBOutlet weak var day2Stack: UIStackView!
    @IBOutlet weak var day2Hours: UILabel!
    @IBOutlet weak var day2Note: UILabel!
    @IBOutlet weak var day3Stack: UIStackView!
    @IBOutlet weak var day3Hours: UILabel!
    @IBOutlet weak var day3Note: UILabel!
    @IBOutlet weak var day4Stack: UIStackView!
    @IBOutlet weak var day4Hours: UILabel!
    @IBOutlet weak var day4Note: UILabel!
    @IBOutlet weak var day5Stack: UIStackView!
    @IBOutlet weak var day5Hours: UILabel!
    @IBOutlet weak var day5Note: UILabel!
    @IBOutlet weak var day6Stack: UIStackView!
    @IBOutlet weak var day6Hours: UILabel!
    @IBOutlet weak var day6Note: UILabel!
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

        Task { await fetchData() }
    }

    //MARK: - Functions

    @MainActor
    func fetchData() async {
        guard let account = App.account,
              let orgID = self.orgID,
              let org = Organization.find(byId: orgID) else { return }

        activityIndicator.startAnimating()

        do {
            _ = try await (
                App.serviceConfig.orgService.loadOrgSettings(forOrgID: orgID),
                App.serviceConfig.orgService.loadOrgDetails(account: account, forOrgID: orgID)
            )
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()

        onOrgTreeLoaded()
        onOrgLoaded(org)
        onHoursLoaded(org)
        onClosuresLoaded(org)
        onAddressLoaded(org)
    }

    func setupViews() {
        setupActivityIndicator()
        self.setupHomeButton()
        self.setupActionButtons()
        self.setupHoursViews()
    }

    func setupActionButtons() {
        Style.styleButton(asOutline: orgButton)
        Style.styleButton(asPlain: webSiteButton, trimLeadingInset: true)
        Style.styleButton(asPlain: mapButton, trimLeadingInset: true)
        Style.styleButton(asPlain: emailButton, trimLeadingInset: true)
        Style.styleButton(asPlain: phoneButton, trimLeadingInset: true)
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

    func onOrgLoaded(_ org: Organization) {
        orgButton.isEnabled = true
        orgButton.setTitle(org.name, for: .normal)

        if let infoURL = org.infoURL, !infoURL.isEmpty {
            webSiteButton.isEnabled = true
        } else {
            webSiteButton.isEnabled = false
        }
        if let email = org.email, !email.isEmpty {
            emailButton.isEnabled = true
            emailButton.setTitle(email, for: .normal)
        } else {
            emailButton.isEnabled = false
            emailButton.setTitle(nil, for: .normal)
        }
        if let number = org.phoneNumber, !number.isEmpty {
            phoneButton.isEnabled = true
            phoneButton.setTitle(number, for: .normal)
        } else {
            phoneButton.isEnabled = false
            phoneButton.setTitle(nil, for: .normal)
        }
    }

    func onAddressLoaded(_ org: Organization) {
        if let obj = org.addressObj, let _ = mapsURL(obj) {
            mapButton.isEnabled = true
        } else {
            mapButton.isEnabled = false
        }
    }

    @objc func orgButtonPressed(sender: UIButton) {
        guard orgLabels.count > 0 else { return }
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }

        vc.title = "Library"
        vc.option = PickOneOption(optionLabels: Organization.getSpinnerLabels(), optionValues: Organization.getShortNames(), optionIsPrimary: Organization.getIsPrimary())
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

    func testNote(_ note: String?) -> String? {
        return note
    }

    func onHoursLoaded(_ org: Organization) {
        day0Hours.text = org.hours?.day0Hours
        day1Hours.text = org.hours?.day1Hours
        day2Hours.text = org.hours?.day2Hours
        day3Hours.text = org.hours?.day3Hours
        day4Hours.text = org.hours?.day4Hours
        day5Hours.text = org.hours?.day5Hours
        day6Hours.text = org.hours?.day6Hours

        day0Note.text = testNote(org.hours?.day0Note)
        day1Note.text = testNote(org.hours?.day1Note)
        day2Note.text = testNote(org.hours?.day2Note)
        day3Note.text = testNote(org.hours?.day3Note)
        day4Note.text = testNote(org.hours?.day4Note)
        day5Note.text = testNote(org.hours?.day5Note)
        day6Note.text = testNote(org.hours?.day6Note)
    }

    func onClosuresLoaded(_ org: Organization) {
        let closures = Array(org.closures.prefix(App.config.upcomingClosuresLimit))

        // clear all existing rows
        while let view = closuresStack.arrangedSubviews.first {
            view.removeFromSuperview()
        }

        // add message if none
        if closures.isEmpty {
            closuresStack.addArrangedSubview(makeClosureRow(firstString: "No closures scheduled"))
            return
        }
        closuresStack.addArrangedSubview(makeClosureRow(firstString: "Date", secondString: "Reason for Closure", isHeader: true))

        // add a row per closure
        for closure in closures {
            closuresStack.addArrangedSubview(makeClosureRow(closure))
        }
    }

    func makeClosureRow(_ closure: XOrgClosure) -> UIView {
        let info = closure.toInfo()
        return makeClosureRow(firstString: info.dateString, secondString: info.reason)
    }

    func makeClosureRow(firstString: String, secondString: String? = nil, isHeader: Bool? = false) -> UIView {

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

        // get an accessible font
        var font = UIFont.preferredFont(forTextStyle: .footnote)
        if isHeader == true {
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
            if let boldDescriptor = descriptor.withSymbolicTraits(.traitBold) {
                font = UIFont(descriptor: boldDescriptor, size: 0.0)
            }
        }

        // add first label
        let firstLabel = UILabel()
        firstLabel.font = font
        firstLabel.adjustsFontForContentSizeCategory = true
        firstLabel.text = firstString
        stackView.addArrangedSubview(firstLabel)

        if secondString != nil {
            // set constraints on first label only if we have a second
            let width = 0.40
            firstLabel.numberOfLines = 0
            firstLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: width).isActive = true

            // add second label
            let secondLabel = UILabel()
            //secondLabel.backgroundColor = UIColor.lightGray // hack to visualize layout
            secondLabel.font = font
            secondLabel.adjustsFontForContentSizeCategory = true
            secondLabel.text = secondString
            secondLabel.numberOfLines = 0
            stackView.addArrangedSubview(secondLabel)
        }

        return stackView
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
