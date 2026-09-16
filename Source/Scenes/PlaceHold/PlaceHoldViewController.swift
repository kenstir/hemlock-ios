//
//  Copyright (C) 2024 Kenneth H. Cox
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
import os.log

enum HoldLayout: String {
    case titleHold
    case partHold
    case editHold
    case advancedHold
}

class PlaceHoldViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var partSelectStack: UIStackView!
    @IBOutlet weak var phoneNotifyStack: UIStackView!
    @IBOutlet weak var expirationStack: UIStackView!
    @IBOutlet weak var suspendStack: UIStackView!
    @IBOutlet weak var thawStack: UIStackView!

    @IBOutlet weak var partTextField: UITextField!
    @IBOutlet weak var pickupTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var smsNumberTextField: UITextField!
    @IBOutlet weak var carrierTextField: UITextField!
    @IBOutlet weak var expirationDatePicker: UIDatePicker!
    @IBOutlet weak var thawDatePicker: UIDatePicker!

    @IBOutlet weak var emailSwitch: UISwitch!
    @IBOutlet weak var phoneSwitch: UISwitch!
    @IBOutlet weak var smsSwitch: UISwitch!
    @IBOutlet weak var suspendSwitch: UISwitch!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var formatLabel: UILabel!

    @IBOutlet weak var advancedOptionsTable: UITableView!
    @IBOutlet var advancedOptionsTableHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var advancedHoldButton: UIButton!

    @IBOutlet var labels: [UILabel]!

    var record: BibRecord!
    var holdRecord: HoldRecord?
    var layout = HoldLayout.titleHold
    var parts: [HoldPart] = []
    var valueChangedHandler: (() -> Void)?

    var partLabels: [String] = []
    var orgLabels: [String] = []
    var carrierLabels: [String] = []
    var selectedPartLabel = ""
    var selectedOrgIndex = 0
    var selectedCarrierName = ""
    var didCompleteFetch = false
    var expirationDate: Date? = nil
    var thawDate: Date? = nil

    var holdableFormats: [String] = []
    var holdableLangs: [String] = []
    var selectedFormats: [String] = []
    var selectedLangs: [String] = []

    var activityIndicator: UIActivityIndicatorView!

    var isEditHold: Bool { return holdRecord != nil }
    var hasParts: Bool { return !parts.isEmpty }
    var titleHoldIsPossible: Bool? = nil
    var partRequired: Bool { return hasParts && titleHoldIsPossible != true }

    //MARK: - Lifecycle

    static func make(record: BibRecord, holdRecord: HoldRecord? = nil, layout: HoldLayout = .titleHold, valueChangedHandler: (() -> Void)? = nil) -> PlaceHoldViewController? {
        if let vc = UIStoryboard(name: "PlaceHold", bundle: nil).instantiateInitialViewController() as? PlaceHoldViewController {
            vc.record = record
            vc.holdRecord = holdRecord
            vc.layout = (holdRecord != nil) ? .editHold : layout
            vc.valueChangedHandler = valueChangedHandler
            return vc
        }
        return nil
    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = switch layout {
        case .titleHold: "Place Hold"
        case .partHold: "Place Hold"
        case .editHold: "Edit Hold"
        case .advancedHold: "Advanced Hold"
        }
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.setupTapToDismissKeyboard(onScrollView: scrollView)
        scrollView.setupKeyboardAutoResizer()

        Task { await self.fetchData() }
    }

    //MARK: - Setup Functions

    func setupViews() {
        setupMetadataLabels()
        setupLabelAlignment()

        setupPartRow()
        setupPickupRow()
        setupEmailRow()
        setupPhoneRow()
        setupSmsRow()
        setupCarrierRow()
        setupExpirationRow()
        setupSuspendRow()
        setupThawRow()
        setupAdvancedOptionsTable()
        setupButtonRow()

        setupActivityIndicator()

        enableViewsWhenReady()
    }

    func setupMetadataLabels() {
        titleLabel.text = record.title
        authorLabel.text = record.author
        formatLabel.text = record.iconFormatLabel
    }

    func setupPartRow() {
        partTextField.addDisclosureIndicator()
        partTextField.delegate = self
    }

    func setupPickupRow() {
        pickupTextField.addDisclosureIndicator()
        pickupTextField.delegate = self
    }

    func setupCarrierRow() {
        carrierTextField.addDisclosureIndicator()
        carrierTextField.delegate = self
    }

    func setupEmailRow() {
        emailSwitch.addTarget(self, action: #selector(emailSwitchChanged(sender:)), for: .valueChanged)
    }

    func setupPhoneRow() {
        phoneSwitch.addTarget(self, action: #selector(phoneSwitchChanged(sender:)), for: .valueChanged)
        phoneTextField.keyboardType = .phonePad
        phoneTextField.delegate = self
        phoneTextField.addTarget(self, action: #selector(phoneTextChanged), for: [.editingDidEnd, .editingDidEndOnExit])
    }

    func setupSmsRow() {
        smsSwitch.addTarget(self, action: #selector(smsSwitchChanged(sender:)), for: .valueChanged)
        smsNumberTextField.keyboardType = .phonePad
        smsNumberTextField.delegate = self
        smsNumberTextField.addTarget(self, action: #selector(smsTextChanged), for: [.editingDidEnd, .editingDidEndOnExit])
    }

    func setupSuspendRow() {
        suspendSwitch.addTarget(self, action: #selector(suspendSwitchChanged(sender:)), for: .valueChanged)
    }

    func setupExpirationRow() {
        expirationDatePicker.addTarget(self, action: #selector(expirationChanged(sender:)), for: .valueChanged)
        expirationDatePicker.contentHorizontalAlignment = .left
    }

    func setupThawRow() {
        thawDatePicker.addTarget(self, action: #selector(thawChanged(sender:)), for: .valueChanged)
        thawDatePicker.contentHorizontalAlignment = .left
    }

    func setupAdvancedOptionsTable() {
        advancedOptionsTable.delegate = self
        advancedOptionsTable.dataSource = self

        // Disable the table's inner scroll
        advancedOptionsTable.isScrollEnabled = false
        advancedOptionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "advancedHoldOptionsCell")

        // Use the zero-height IBOutlet constraint; we will change it if there are rows to display.
        // Add it in IB instead of code because if we don't, IB generates a Missing Constraints warning.
        //advancedOptionsHeightConstraint = advancedOptionsTable.heightAnchor.constraint(equalToConstant: 0)
        advancedOptionsTableHeightConstraint.isActive = true
    }

    func setupButtonRow() {
        actionButton.setTitle(isEditHold ? "Update Hold" : "Place Hold", for: .normal)
        actionButton.addTarget(self, action: #selector(holdButtonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: actionButton)

        advancedHoldButton.addTarget(self, action: #selector(advancedHoldButtonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asOutline: advancedHoldButton)
        advancedHoldButton.isHidden = true
    }

    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func enableViewsWhenReady() {
        partSelectStack.isHidden = !hasParts

        // these fields aren't available until we fetch
        pickupTextField.isEnabled = didCompleteFetch
        carrierTextField.isEnabled = didCompleteFetch
        actionButton.isEnabled = didCompleteFetch

        // phone number row is shown only when configured
        phoneNotifyStack.isHidden = !App.config.enableHoldPhoneNotification

        // for a simpler UX, suspend/thaw are hidden when placing a hold
        expirationStack.isHidden = !isEditHold
        suspendStack.isHidden = !isEditHold
        thawStack.isHidden = !isEditHold

        // phone numbers are enabled based on their switches
        phoneTextField.isEnabled = phoneSwitch.isOn
        smsNumberTextField.isEnabled = smsSwitch.isOn

        // The suspend switch has a bunch of effects.
        // When disabling a date picker, we also set the alpha because it doesn't allow
        // a nil or empty date and showing the current date in full alpha is confusing.
        expirationDatePicker.isEnabled = !suspendSwitch.isOn
        expirationDatePicker.alpha = suspendSwitch.isOn ? 0.25 : 1.0
        thawDatePicker.isEnabled = suspendSwitch.isOn
        thawDatePicker.alpha = suspendSwitch.isOn ? 1.0 : 0.25

        // metarecord hold views may be hidden
        advancedOptionsTable.isHidden = (layout != .advancedHold)
        advancedHoldButton.isHidden = (layout != .titleHold)
    }

    func setupLabelAlignment() {
        // find the widest label whose superview (Hstack) is visible
        guard let widestLabel = labels.max(by: { ($1.superview?.isHidden == false) && $1.frame.width > $0.frame.width }) else { return }
        print("widest: \(widestLabel.text ?? "") \(widestLabel.frame.width)")

        // Set a minimum width constraint to *slightly bigger* than the widest label wants to be.
        // Setting an equalTo constraint resulted in all the labels being too thin and ellipsized.
        let minWidth = widestLabel.frame.width + 8.0
        for label in labels {
            print("label: \(label.text ?? "") new min width \(minWidth)")
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        }
    }

    //MARK: - Async Functions

    @MainActor
    func fetchData() async {
        guard !didCompleteFetch else { return }
        guard let account = App.account else { return }

        let startOfFetch = Date()

        activityIndicator.startAnimating()

        do {
            async let prereq: Void = App.svc.loader.loadPlaceHoldPrerequisites()
            async let parts: Void = fetchPartsData(account: account)
            async let metaStuff: Void = fetchMetarecordStuff(account: account)
            _ = try await (prereq, parts, metaStuff)
            self.didCompleteFetch = true
            self.onDataLoaded()
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()

        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("fetch.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
    }

    func fetchPartsData(account: Account) async throws {
        if !App.config.enablePartHolds || isEditHold {
            return
        }
        print("PlaceHold: \(record.title): fetching parts")

        self.parts = try await App.svc.circ.fetchHoldParts(targetID: record.id)

        if self.hasParts {
            layout = .partHold
        }

        // If the app config permits title holds on parted items, check if it's allowed on this particular item
        if self.hasParts,
           App.config.enableTitleHoldOnItemWithParts,
           let pickupOrgID = account.pickupOrgID
        {
            print("PlaceHold: \(self.record.title): checking titleHoldIsPossible")
            do {
                let _ = try await App.svc.circ.fetchTitleHoldIsPossible(account: account, targetID: self.record.id, pickupOrgID: pickupOrgID)
                self.titleHoldIsPossible = true
            } catch {
                self.titleHoldIsPossible = false
            }
            print("PlaceHold: \(self.record.title): titleHoldIsPossible=\(Utils.toString(self.titleHoldIsPossible))")
        }
    }

    func fetchMetarecordStuff(account: Account) async throws {
        guard let targetId = record.metarecordID, layout == .advancedHold else {
            return
        }
        print("PlaceHold: \(record.title): fetching metarecord hold options")

        let pickupOrg = App.svc.consortium.visibleOrgs[selectedOrgIndex]
        let options = try await App.svc.circ.fetchMetarecordHoldOptions(account: account, targetID: targetId, pickupOrgID: pickupOrg.id)
        self.holdableFormats = options.formatCodes
        self.holdableLangs = options.languageCodes
    }

    //MARK: - Options State Management

    func toInt(_ str: String?) -> Int? {
        if let s = str {
            return Int(s)
        }
        return nil
    }

    // init that can't happen until fetchData completes
    func onDataLoaded() {
        loadNotifyData()
        loadPartData()
        loadOrgData()
        loadCarrierData()
        loadExpirationData()
        loadAdvancedHoldData()
        enableViewsWhenReady()
        App.svc.consortium.dumpOrgStats()
    }

    func loadNotifyData() {
        if let val = Utils.coalesce(holdRecord?.hasEmailNotify,
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyByEmail),
                                    App.account?.notifyByEmail) {
            emailSwitch.isOn = val
        }

        // Allow phone_notify to be set even if UX is not visible
        let phoneNumber = Utils.coalesce(holdRecord?.phoneNotify,
                                         AppState.sensitiveString(forKey: AppState.Str.holdPhoneNumber),
                                         App.account?.phoneNumber)
        phoneTextField.text = phoneNumber
        if let val = Utils.coalesce(holdRecord?.hasPhoneNotify,
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyByPhone),
                                    App.account?.notifyByPhone),
            let str = phoneNumber,
            !str.isEmpty
        {
            phoneSwitch.isOn = val
        }

        let smsNumber = Utils.coalesce(holdRecord?.smsNotify,
                                       AppState.sensitiveString(forKey: AppState.Str.holdSMSNumber),
                                       App.account?.smsNumber)
        smsNumberTextField.text = smsNumber
        if let val = Utils.coalesce(holdRecord?.hasSmsNotify,
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyBySMS),
                                    App.account?.notifyBySMS),
            let str = smsNumber,
            !str.isEmpty
        {
            smsSwitch.isOn = val
        }
    }

    func loadCarrierData() {
        carrierLabels = App.svc.consortium.smsCarrierSpinnerLabels
        carrierLabels.sort()
        carrierLabels.insert("---", at: 0)

        let defaultCarrierID = Utils.coalesce(holdRecord?.smsCarrier,
                                              AppState.integer(forKey: AppState.Integer.holdSMSCarrierID),
                                              App.account?.smsCarrierID)

        let selectedCarrier = App.svc.consortium.smsCarriers.first(where: { $0.id == defaultCarrierID })
        selectedCarrierName = selectedCarrier?.name ?? carrierLabels[0]
        carrierTextField.text = selectedCarrierName
        carrierTextField.isUserInteractionEnabled = true
    }

    func loadPartData() {
        let sentinelString = partRequired ? "---" : "- \(R.getString("Any part")) -"
        partLabels = [sentinelString]
        for part in parts {
            partLabels.append(part.label)
        }

        selectedPartLabel = partLabels[0]
        partTextField.text = selectedPartLabel
        partTextField.isUserInteractionEnabled = true
    }

    func defaultExpirationDate() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    func defaultThawDate() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    func loadExpirationData() {
        // Unlike the other load* methods, this does not need to wait for fetchData to complete.
        // Leaving it hear for now for consistency.
        suspendSwitch.isOn = holdRecord?.isSuspended ?? false
        if let date = holdRecord?.expireDate {
            expirationDate = date
            expirationDatePicker.date = date
        } else {
            expirationDatePicker.date = defaultExpirationDate()
        }
        if let date = holdRecord?.thawDate {
            thawDate = date
            thawDatePicker.date = date
        } else {
            thawDatePicker.date = defaultThawDate()
        }
    }

    func loadAdvancedHoldData() {
        guard layout == .advancedHold else { return }
        advancedOptionsTable.reloadData()
        advancedOptionsTable.layoutIfNeeded()
        advancedOptionsTableHeightConstraint.constant = advancedOptionsTable.contentSize.height
    }

    @objc func expirationChanged(sender: UIDatePicker) {
        expirationDate = sender.date
    }

    @objc func thawChanged(sender: UIDatePicker) {
        thawDate = sender.date
    }

    @objc func holdButtonPressed(sender: Any) {
        placeOrUpdateHold()
    }

    @objc func advancedHoldButtonPressed(sender: Any) {
        guard let vc = PlaceHoldViewController.make(record: record, holdRecord: nil, layout: .advancedHold) else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func suspendSwitchChanged(sender: UISwitch) {
        enableViewsWhenReady()
        // Hold objects can have null dates, but date pickers can't.
        // Since thawDate is displayed, make sure it's not null.
        if suspendSwitch.isOn {
            thawDate = thawDatePicker.date
        }
    }

    @objc func emailSwitchChanged(sender: Any) {
        AppState.set(bool: emailSwitch.isOn, forKey: AppState.Boolean.holdNotifyByEmail)
    }

    @objc func phoneSwitchChanged(sender: Any) {
        enableViewsWhenReady()
        AppState.set(bool: phoneSwitch.isOn, forKey: AppState.Boolean.holdNotifyByPhone)
    }

    @objc func smsSwitchChanged(sender: Any) {
        enableViewsWhenReady()
        AppState.set(bool: smsSwitch.isOn, forKey: AppState.Boolean.holdNotifyBySMS)
    }

    @objc func phoneTextChanged(sender: UITextField) {
        if let phoneNumber = sender.text?.trim(), !phoneNumber.isEmpty {
            AppState.set(sensitiveString: phoneNumber, forKey: AppState.Str.holdPhoneNumber)
        }
    }

    @objc func smsTextChanged(sender: UITextField) {
        if let smsNumber = sender.text?.trim(), !smsNumber.isEmpty {
            AppState.set(sensitiveString: smsNumber, forKey: AppState.Str.holdSMSNumber)
        }
    }

    func saveSelectedCarrier(byName name: String) {
        if let carrier = App.svc.consortium.smsCarriers.first(where: { $0.name == name }) {
            AppState.set(integer: carrier.id, forKey: AppState.Integer.holdSMSCarrierID)
        }
    }

    //MARK: - Pickup Org Management

    func loadOrgData() {
        // The pickup org preference is handled differently from other preferences:
        // * it always defaults to the account setting
        // * changing it results in an JUST ONCE / ALWAYS alert
        // * ALWAYS saves it back to the account
        let consortiumService = App.svc.consortium
        orgLabels = consortiumService.orgSpinnerLabels

        let defaultPickupOrgID = Utils.coalesce(holdRecord?.pickupOrgID,
                                                App.account?.pickupOrgID)

        selectedOrgIndex = consortiumService.visibleOrgs.firstIndexOrZero(where: { $0.id == defaultPickupOrgID })
        let label = orgLabels[selectedOrgIndex].trim()
        pickupTextField.text = label
        print("[prefs] Pickup org: default is \(label)")

        pickupTextField.isUserInteractionEnabled = true
    }

    func maybeChangePickupOrg(newIndex: Int, newLabel: String) {
        let consortiumService = App.svc.consortium
        let newOrg = consortiumService.visibleOrgs[newIndex]
        print("[prefs] Pickup org: selected \(newOrg.name)")
        guard newIndex != selectedOrgIndex else { return }

        if newOrg.id == App.account?.pickupOrgID {
            print("[prefs] Pickup org: same as account setting")
            selectedOrgIndex = newIndex
            pickupTextField.text = newLabel
            return
        }

        let alertController = UIAlertController(title: "Change pickup location?", message: "Change pickup location to \(newOrg.name)?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("[prefs] Pickup org: cancel")
        })
        alertController.addAction(UIAlertAction(title: "Just once", style: .default) { _ in
            print("[prefs] Pickup org: just once")
            self.selectedOrgIndex = newIndex
            self.pickupTextField.text = newLabel
        })
        alertController.addAction(UIAlertAction(title: "Always", style: .default) { _ in
            print("[prefs] Pickup org: always")
            self.selectedOrgIndex = newIndex
            self.pickupTextField.text = newLabel
            Task { await self.saveSelectedPickupOrg(org: newOrg) }
        })

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.pickupTextField
            popoverController.sourceRect = self.pickupTextField.bounds
        }
        self.present(alertController, animated: true)
    }

    @MainActor
    func saveSelectedPickupOrg(org: Organization) async {
        guard let account = App.account else { return }
        do {
            try await App.svc.user.changePickupOrg(account: account, orgID: org.id)
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    //MARK: - Place/Update Hold

    func placeOrUpdateHold() {
        guard let account = App.account else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        let pickupOrg = App.svc.consortium.visibleOrgs[selectedOrgIndex]
        if !pickupOrg.isPickupLocation {
            self.showAlert(title: "Not a pickup location", message: "You cannot pick up items at \(pickupOrg.name)")
            return
        }
        var holdType: String
        var targetID: Int
        let partID = parts.first(where: {$0.label == selectedPartLabel})?.id
        if partRequired || partID != nil {
            holdType = API.holdTypePart
            guard let id = partID else {
                self.showAlert(title: "No part selected", message: "You must select a part before placing a hold on this item")
                return
            }
            targetID = id
        } else if layout == .advancedHold {
            holdType = API.holdTypeMetarecord
            if holdableFormats.count > 1 && selectedFormats.isEmpty {
                self.showAlert(title: "No format selected", message: "You must select at least one format before placing a hold on this item")
                return
            }
            if holdableLangs.count > 1 && selectedLangs.isEmpty {
                self.showAlert(title: "No language selected", message: "You must select at least one language before placing a hold on this item")
                return
            }
            targetID = record.metarecordID ?? record.id
        } else {
            holdType = API.holdTypeTitle
            targetID = record.id
        }

        var notifyPhoneNumber: String? = nil
        var notifySMSNumber: String? = nil
        var notifyCarrierID: Int? = nil
        if phoneSwitch.isOn {
            guard let phoneNumber = phoneTextField.text?.trim(), !phoneNumber.isEmpty else {
                self.showAlert(title: "Error", message: "Phone number cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNumber
        } else if isEditHold {
            notifyPhoneNumber = nil
        }
        if smsSwitch.isOn {
            guard let smsNumber = smsNumberTextField.text?.trim(), !smsNumber.isEmpty else {
                self.showAlert(title: "Error", message: "SMS phone number cannot be empty")
                return
            }
            guard let carrier = App.svc.consortium.smsCarriers.first(where: { $0.name == selectedCarrierName }) else {
                self.showAlert(title: "Error", message: "Please select a valid carrier")
                return
            }
            notifySMSNumber = smsNumber
            notifyCarrierID = carrier.id
        } else if isEditHold {
            notifySMSNumber = nil
            notifyCarrierID = nil
        }

        if let hold = holdRecord {
            Task { await doUpdateHold(account: account, holdRecord: hold, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID) }
        } else {
            Task { await doPlaceHold(account: account, holdType: holdType, targetID: targetID, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID) }
        }
    }

    @MainActor
    func doPlaceHold(account: Account, holdType: String, targetID: Int, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) async {
        activityIndicator.startAnimating()

        let eventParams = placeHoldEventParams(holdType: holdType, selectedOrg: pickupOrg)
        do {
            let options = HoldOptions(
                holdType: holdType,
                useOverride: App.config.enableHoldUseOverride,
                notifyByEmail: emailSwitch.isOn,
                phoneNotify: notifyPhoneNumber,
                smsNotify: notifySMSNumber,
                smsCarrierID: notifyCarrierID,
                pickupOrgID: pickupOrg.id,
                metarecordHoldOptions: (layout == .advancedHold) ? MetarecordHoldOptions(formatCodes: selectedFormats, languageCodes: selectedLangs) : nil
            )
            let _ = try await App.svc.circ.placeHold(account: account, targetID: targetID, withOptions: options)
            activityIndicator.stopAnimating()
            self.logPlaceHold(params: eventParams)
            self.valueChangedHandler?()
            self.navigationController?.view.makeToast("Hold successfully placed")
            self.popAfterSuccess()
        } catch {
            activityIndicator.stopAnimating()
            self.logPlaceHold(withError: error, params: eventParams)
            self.presentGatewayAlert(forError: error)
        }
    }

    // Pop navigation stack back to the VC prior to the PlaceHold VC.  In the case of Advanced Hold that means 2 back.
    func popAfterSuccess() {
        if layout == .advancedHold,
           let vcStack = self.navigationController?.viewControllers,
           vcStack.count >= 3
        {
            self.navigationController?.popToViewController(vcStack[vcStack.count - 3], animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @MainActor
    func doUpdateHold(account: Account, holdRecord: HoldRecord, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) async {
        activityIndicator.startAnimating()

        let eventParams: [String: Any] = [Analytics.Param.holdSuspend: Analytics.boolValue(suspendSwitch.isOn)]
        do {
            let options = HoldUpdateOptions(notifyByEmail: emailSwitch.isOn, phoneNotify: notifyPhoneNumber, smsNotify: notifySMSNumber, smsCarrierID: notifyCarrierID, pickupOrgID: pickupOrg.id, expirationDate: expirationDate, suspended: suspendSwitch.isOn, thawDate: thawDate)
            let _ = try await App.svc.circ.updateHold(account: account, holdID: holdRecord.id, withOptions: options)
            activityIndicator.stopAnimating()
            self.logUpdateHold(params: eventParams)
            self.valueChangedHandler?()
            self.navigationController?.view.makeToast("Hold successfully updated")
            self.navigationController?.popViewController(animated: true)
        } catch {
            activityIndicator.stopAnimating()
            self.logUpdateHold(withError: error, params: eventParams)
            self.presentGatewayAlert(forError: error)
        }
    }

    private func placeHoldEventParams(holdType: String, selectedOrg: Organization) -> [String: Any] {
        let defaultOrg = App.svc.consortium.find(byID: App.account?.pickupOrgID)
        let homeOrg = App.svc.consortium.find(byID: App.account?.homeOrgID)

        return [
            Analytics.Param.holdType: holdType,
            Analytics.Param.holdNotify: Analytics.notifyDimension(notifyByEmail: emailSwitch.isOn, notifyByPhone: phoneSwitch.isOn, notifyBySMS: smsSwitch.isOn),
            Analytics.Param.holdPickupKey: Analytics.orgDimension(selectedOrg: selectedOrg, defaultOrg: defaultOrg, homeOrg: homeOrg)
        ]
    }

    private func logPlaceHold(withError error: Error? = nil, params: [String: Any]) {
        var eventParams: [String: Any] = params
        if let err = error {
            eventParams[Analytics.Param.result] = err.localizedDescription
        } else {
            eventParams[Analytics.Param.result] = Analytics.Value.ok
        }
        Analytics.logEvent(event: Analytics.Event.placeHold, parameters: eventParams)
    }

    private func logUpdateHold(withError error: Error? = nil, params: [String: Any]) {
        var eventParams: [String: Any] = params
        if let err = error {
            eventParams[Analytics.Param.result] = err.localizedDescription
        } else {
            eventParams[Analytics.Param.result] = Analytics.Value.ok
        }
        Analytics.logEvent(event: Analytics.Event.updateHold, parameters: eventParams)
    }

    func makeOptionVC(title: String) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        return vc
    }
}

//MARK: - UITextFieldDelegate
extension PlaceHoldViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let consortiumService = App.svc.consortium

        switch textField {
        case pickupTextField:
            guard let vc = makeOptionVC(title: "Pickup Location") else { return true }
            vc.option = PickOneOption(optionLabels: orgLabels, optionIsEnabled: consortiumService.orgSpinnerIsPickupLocationFlags, optionIsPrimary: consortiumService.orgSpinnerIsPrimaryFlags)
            vc.selectedIndex = selectedOrgIndex
            vc.selectionChangedHandler = { index, trimmedLabel in
                // postpone any possible alert until after OptionsVC is popped
                DispatchQueue.main.asyncAfter(deadline: .now() + OptionsViewController.postSelectionDelay + 0.050) {
                    self.maybeChangePickupOrg(newIndex: index, newLabel: trimmedLabel)
                }
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case carrierTextField:
            guard let vc = makeOptionVC(title: "SMS Carrier") else { return true }
            vc.option = PickOneOption(optionLabels: carrierLabels)
            vc.selectedIndex = carrierLabels.firstIndex(of: selectedCarrierName)
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedCarrierName = trimmedLabel
                self.carrierTextField.text = trimmedLabel
                self.saveSelectedCarrier(byName: trimmedLabel)
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case partTextField:
            guard let vc = makeOptionVC(title: "Select a part") else { return true }
            vc.option = PickOneOption(optionLabels: partLabels)
            vc.selectedIndex = partLabels.firstIndex(of: selectedPartLabel)
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedPartLabel = self.partLabels[index]
                self.partTextField.text = trimmedLabel
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        default:
            return true
        }
    }
}

//MARK: - UITableViewDataSource
extension PlaceHoldViewController: UITableViewDataSource {
    func isSelected(code: String, in selectedArray: [String]) -> Bool {
        return selectedArray.contains(code)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // formats and languages
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return holdableFormats.count
        } else if section == 1 {
            return holdableLangs.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Desired formats"
        } else {
            return "Desired languages"
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHalfHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "advancedHoldOptionsCell", for: indexPath)

        let label: String
        let isChecked: Bool
        if indexPath.section == 0 {
            let code = holdableFormats[indexPath.row]
            label = App.svc.biblio.iconFormatLabel(forCode: code)
            isChecked = isSelected(code: code, in: selectedFormats)
        } else {
            let code = holdableLangs[indexPath.row]
            label = App.svc.biblio.languageLabel(forCode: code)
            isChecked = isSelected(code: code, in: selectedLangs)
        }

        cell.textLabel?.text = label
        cell.accessoryType = (isChecked ? .checkmark : .none)

        return cell
    }
}

//MARK: - UITableViewDelegate
extension PlaceHoldViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var isChecked: Bool
        if indexPath.section == 0 {
            let code = holdableFormats[indexPath.row]
            if let index = selectedFormats.firstIndex(of: code) {
                selectedFormats.remove(at: index)
                isChecked = false
            } else {
                selectedFormats.append(code)
                isChecked = true
            }
            print("\(code) \((isChecked ? "selected" : "UNSELECTED"))")
        } else {
            let code = holdableLangs[indexPath.row]
            if let index = selectedLangs.firstIndex(of: code) {
                selectedLangs.remove(at: index)
                isChecked = false
            } else {
                selectedLangs.append(code)
                isChecked = true
            }
            print("\(code) \((isChecked ? "selected" : "UNSELECTED"))")
        }

        tableView.cellForRow(at: indexPath)!.accessoryType = (isChecked ? .checkmark : .none)
    }
}
