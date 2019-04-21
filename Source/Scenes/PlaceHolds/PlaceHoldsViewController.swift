//
//  PlaceHoldsViewController.swift
//
//  Copyright (C) 2018 Erik Cox
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
import PromiseKit
import PMKAlamofire
import os.log

class PlaceHoldsViewController: UIViewController {

    //MARK: - Properties
    var record: MBRecord?
    let formats = Format.getSpinnerLabels()
    var orgLabels: [String] = []
    var carrierLabels: [String] = []
    var selectedOrgName = ""
    var selectedCarrierName = ""
    var startOfFetch = Date()

    weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneStack: UIStackView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneSwitch: UISwitch!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var holdsTitleLabel: UILabel!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var locationPicker: UITextField!
    @IBOutlet weak var holdsAuthorLabel: UILabel!
    @IBOutlet weak var smsNumber: UITextField!
    @IBOutlet weak var carrierPicker: UITextField!
    @IBOutlet weak var emailSwitch: UISwitch!
    @IBAction func phoneSwitchAction(_ sender: Any) {
        setupPhoneSwitch()
    }
    @IBOutlet weak var smsSwitch: UISwitch!
    @IBAction func smsSwitchAction(_ sender: Any) {
        setupSMSSwitch()
    }
    @IBOutlet weak var placeHoldButton: UIButton!
    @IBAction func placeHoldButtonPressed(_ sender: UIButton) {
        self.placeHold()
    }
    
    //MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }

    func setupViews() {
        holdsTitleLabel.text = record?.title
        formatLabel.text = record?.format
        holdsAuthorLabel.text = record?.author
        locationPicker.isUserInteractionEnabled = false
        carrierPicker.isUserInteractionEnabled = false

        if let val = App.account?.defaultNotifyEmail {
            emailSwitch.isOn = val
        }

        if !App.config.enableHoldPhoneNotification  {
            phoneStack.isHidden = true
            phoneLabel.isHidden = true
            phoneSwitch.isHidden = true
            phoneNumber.isHidden = true
        } else if let val = App.account?.defaultNotifyPhone {
            phoneSwitch.isOn = val
            if let number = App.account?.phone {
                phoneNumber.text = number
            }
        }
        setupPhoneSwitch()

        smsNumber.delegate = self
        if let number = App.account?.smsNotify {
            smsNumber.text = number
        } else {
            smsNumber.text = App.valet.string(forKey: "SMSNumber") ?? ""
        }
        if let val = App.account?.defaultNotifySMS {
            smsSwitch.isOn = val
        }
        setupSMSSwitch()
        
        placeHoldButton.isEnabled = false
        Style.styleButton(asInverse: placeHoldButton)
        
        setupActivityIndicator()
        self.setupHomeButton()
        self.setupTapToDismissKeyboard(onScrollView: scrollView)
        self.scrollView.setupKeyboardAutoResizer()
    }

    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func setupLocationPicker() {
        self.orgLabels = Organization.getSpinnerLabels()
        var selectOrgIndex = 0
        let defaultPickupLocation = App.account?.pickupOrgID
        for index in 0..<Organization.orgs.count {
            let org = Organization.orgs[index]
            if org.id == defaultPickupLocation {
                selectOrgIndex = index
            }
        }
        
        self.selectedOrgName = orgLabels[selectOrgIndex].trim()
        locationPicker.text = orgLabels[selectOrgIndex].trim()
        locationPicker.isUserInteractionEnabled = true
        locationPicker.delegate = self
        locationPicker.addDisclosureIndicator()
    }
    
    func setupCarrierPicker() {
        self.carrierLabels = SMSCarrier.getSpinnerLabels()
        carrierLabels.sort()
        carrierLabels.insert("---", at: 0)

        var selectCarrierName: String?
        var selectCarrierIndex = 0
        if let defaultCarrierID = App.account?.smsCarrier,
            let defaultCarrier = SMSCarrier.find(byID: defaultCarrierID) {
            selectCarrierName = defaultCarrier.name
        } else {
            selectCarrierName = App.valet.string(forKey: "carrier")
        }
        for index in 0..<carrierLabels.count {
            let carrier = carrierLabels[index]
            if carrier == selectCarrierName {
                selectCarrierIndex = index
            }
        }
        
        self.selectedCarrierName = carrierLabels[selectCarrierIndex]
        carrierPicker.text = carrierLabels[selectCarrierIndex]
        carrierPicker.isUserInteractionEnabled = true
        carrierPicker.delegate = self
        carrierPicker.addDisclosureIndicator()
    }
    
    func setupPhoneSwitch() {
        phoneNumber.isUserInteractionEnabled = phoneSwitch.isOn
    }
    
    func setupSMSSwitch() {
        if smsSwitch.isOn {
            smsNumber.isUserInteractionEnabled = true
            carrierPicker.isUserInteractionEnabled = true
        } else {
            smsNumber.isUserInteractionEnabled = false
            carrierPicker.isUserInteractionEnabled = false
        }
    }

    func fetchData() {
        self.startOfFetch = Date()

        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTreeAndSettings())
        promises.append(PCRUDService.fetchSMSCarriers())
        print("xxx \(promises.count) promises made")

        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            let elapsed = -self.startOfFetch.timeIntervalSinceNow
            os_log("fetch.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
            self.setupLocationPicker()
            self.setupCarrierPicker()
            self.placeHoldButton.isEnabled = true
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func placeHold() {
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        guard let recordID = record?.id,
            let pickupOrg = Organization.find(byName: self.selectedOrgName) else
        {
            self.showAlert(title: "Internal error", error: HemlockError.shouldNotHappen("Missing record ID or pickup org"))
            return
        }
        print("pickupOrg \(pickupOrg.id) \(pickupOrg.name) \(pickupOrg.isPickupLocation)")
        if !pickupOrg.isPickupLocation {
            self.showAlert(title: "Not a pickup location", message: "You cannot pick up items at \(pickupOrg.name)")
            return
        }

        var notifyPhoneNumber: String? = nil
        var notifySMSNumber: String? = nil
        var notifyCarrierID: Int? = nil
        if phoneSwitch.isOn
        {
            guard let phoneNotify = phoneNumber.text?.trim(),
                phoneNotify.count > 0 else
            {
                self.showAlert(title: "Error", message: "Phone number field cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNotify
            App.valet.set(string: phoneNotify, forKey: "PhoneNumber")
        }
        if smsSwitch.isOn
        {
            guard let carrier = SMSCarrier.find(byName: self.selectedCarrierName) else {
                self.showAlert(title: "Error", message: "Please select a valid carrier")
                return
            }
            App.valet.set(string: self.selectedCarrierName, forKey: "carrier")
            guard let smsNotify = smsNumber.text?.trim(),
                smsNotify.count > 0 else
            {
                self.showAlert(title: "Error", message: "SMS phone number field cannot be empty")
                return
            }
            notifySMSNumber = smsNotify
            App.valet.set(string: smsNotify, forKey: "SMSNumber")
            notifyCarrierID = carrier.id
        }

        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        let promise = CircService.placeHold(authtoken: authtoken, userID: userID, recordID: recordID, pickupOrgID: pickupOrg.id, notifyByEmail: emailSwitch.isOn, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, smsCarrierID: notifyCarrierID)
        promise.done { obj in
            if let _ = obj.getInt("result") {
                // case 1: result is an Int - hold successful
                self.navigationController?.view.makeToast("Hold successfully placed")
                self.navigationController?.popViewController(animated: true)
                return
            } else if let resultObj = obj.getAny("result") as? OSRFObject,
                let eventObj = resultObj.getAny("last_event") as? OSRFObject
            {
                // case 2: result is an object with last_event - hold failed
                throw self.holdError(obj: eventObj)
            } else if let resultArray = obj.getAny("result") as? [OSRFObject],
                let eventObj = resultArray.first
            {
                // case 3: result is an array of ilsevent objects - hold failed
                throw self.holdError(obj: eventObj)
            } else {
                throw HemlockError.unexpectedNetworkResponse(String(describing: obj.dict))
            }
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func holdError(obj: OSRFObject) -> Error {
        if let ilsevent = obj.getInt("ilsevent"),
            let textcode = obj.getString("textcode"),
            let desc = obj.getString("desc") {
            return GatewayError.event(ilsevent: ilsevent, textcode: textcode, desc: desc)
        }
        return HemlockError.unexpectedNetworkResponse(String(describing: obj))
    }
}

extension PlaceHoldsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return true }

        // TODO: facter out OptionTextField class a la McTextField
        switch textField {
        case locationPicker:
            vc.title = "Pickup Location"
            vc.options = orgLabels
            vc.selectedOption = self.selectedOrgName
            vc.selectionChangedHandler = { value in
                self.selectedOrgName = value
                textField.text = value
            }
        case carrierPicker:
            vc.title = "SMS Carrier"
            vc.options = carrierLabels
            vc.selectedOption = self.selectedCarrierName
            vc.selectionChangedHandler = { value in
                self.selectedCarrierName = value
                textField.text = value
            }
        default:
            return true
        }

        self.navigationController?.pushViewController(vc, animated: true)
        return false
    }
}
