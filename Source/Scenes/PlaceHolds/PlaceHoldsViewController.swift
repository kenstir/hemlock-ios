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
    var homeOrgIndex: Int?
    var carrierLabels: [String] = []
    var selectedOrgName = ""
    var selectedCarrierName = ""
    var startOfFetch = Date()


    weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var holdsTitleLabel: UILabel!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var locationPicker: McTextField!
    @IBOutlet weak var holdsAuthorLabel: UILabel!
    @IBOutlet weak var holdsSMSNumber: UITextField!
    @IBOutlet weak var carrierPicker: McTextField!
    @IBOutlet weak var emailSwitch: UISwitch!
    @IBOutlet weak var smsSwitch: UISwitch!
    @IBAction func smsSwitchAction(_ sender: UISwitch) {
        setupSMSSwitch()
    }
    @IBOutlet weak var placeHoldButton: UIButton!
    @IBAction func placeHoldButtonPressed(_ sender: UIButton) {
        self.placeHold()
    }
    
    //MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicator()
        setupViews()
        fetchData()
        holdsSMSNumber.delegate = self
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func setupLocationPicker() {
        let orgLabels = Organization.getSpinnerLabels()
        var selectOrgIndex = 0
        let defaultPickupLocation = App.account?.pickupOrgID
        for index in 0..<Organization.orgs.count {
            let org = Organization.orgs[index]
            if org.id == defaultPickupLocation {
                selectOrgIndex = index
            }
        }
 
        let mcInputView = McPicker(data: [orgLabels])
        Style.stylePicker(asOrgPicker: mcInputView)
        mcInputView.pickerSelectRowsForComponents = [0: [selectOrgIndex: true]]
        self.selectedOrgName = orgLabels[selectOrgIndex].trim()
        locationPicker.text = orgLabels[selectOrgIndex].trim()
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak self, locationPicker] (selections) in
            self?.selectedOrgName = selections[0]!.trim()
            locationPicker?.text = selections[0]!.trim()
        }
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

        let mcInputView = McPicker(data: [carrierLabels])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        mcInputView.fontSize = 16
        mcInputView.pickerSelectRowsForComponents = [0: [selectCarrierIndex: true]]
        self.selectedCarrierName = carrierLabels[selectCarrierIndex]
        carrierPicker.text = carrierLabels[selectCarrierIndex]
        carrierPicker.inputViewMcPicker = mcInputView
        carrierPicker.doneHandler = { [weak self, carrierPicker] (selections) in
            self?.selectedCarrierName = selections[0]!
            carrierPicker?.text = selections[0]!
        }
        carrierPicker?.isUserInteractionEnabled = false
    }
    
    func setupSMSSwitch() {
        if (smsSwitch.isOn) {
            holdsSMSNumber.isUserInteractionEnabled = true
//            holdsSMSNumber.becomeFirstResponder()
            carrierPicker.isUserInteractionEnabled = true
        } else {
            holdsSMSNumber.isUserInteractionEnabled = false
            carrierPicker.isUserInteractionEnabled = false
        }
    }

    func fetchData() {
        self.startOfFetch = Date()

        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypesArray())
        promises.append(ActorService.fetchOrgTree())
        promises.append(PCRUDService.fetchSMSCarriers())
        print("xxx \(promises.count) promises made")

        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.fetchOrgDetails()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchOrgDetails() {
        var promises: [Promise<Void>] = []

        promises.append(contentsOf: ActorService.fetchOrgSettings())
        print("xxx2 \(promises.count) promises made")
      
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx2 \(promises.count) promises fulfilled")
            let elapsed = -self.startOfFetch.timeIntervalSinceNow
            os_log("fetch.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
            self.setupLocationPicker()
            self.setupCarrierPicker()
        }.catch { error in
            self.showAlert(error: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }

    func setupViews() {
        holdsTitleLabel.text = record?.title
        formatLabel.text = record?.format
        holdsAuthorLabel.text = record?.author
        holdsSMSNumber.isUserInteractionEnabled = false
        if let number = App.account?.smsNotify {
            holdsSMSNumber.text = number
        } else {
            holdsSMSNumber.text = App.valet.string(forKey: "SMSNumber") ?? ""
        }
        if let val = App.account?.defaultNotifyEmail {
            emailSwitch.isOn = val
        }
        if let val = App.account?.defaultNotifySMS {
            smsSwitch.isOn = val
        }
        setupSMSSwitch()
        
        Style.styleButton(asInverse: placeHoldButton)

        self.setupHomeButton()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        holdsSMSNumber.resignFirstResponder()
    }
    
    func placeHold() {
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return
        }
        guard let recordID = record?.id,
            let pickupOrg = Organization.find(byName: self.selectedOrgName) else
        {
            Analytics.logError(code: .shouldNotHappen, msg: "error during prepare", file: #file, line: #line)
            self.showAlert(title: "Internal error", message: "Internal error preparing to place hold")
            return
        }
        print("pickupOrg \(pickupOrg.id) \(pickupOrg.name) \(pickupOrg.isPickupLocation)")
        if !pickupOrg.isPickupLocation {
            self.showAlert(title: "Not a pickup location", message: "You cannot pick up items at \(pickupOrg.name)")
            return
        }

        var notifyPhoneNumber: String? = nil
        var notifyCarrierID: Int? = nil
        if smsSwitch.isOn
        {
            guard let carrier = SMSCarrier.find(byName: self.selectedCarrierName) else {
                self.showAlert(title: "Error", message: "Please select a valid carrier")
                return
            }
            App.valet.set(string: self.selectedCarrierName, forKey: "carrier")
            guard let phoneNumber = holdsSMSNumber.text?.trim(),
                phoneNumber.count > 0 else
            {
                self.showAlert(title: "Error", message: "Phone number field cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNumber
            App.valet.set(string: phoneNumber, forKey: "SMSNumber")
            notifyCarrierID = carrier.id
        }

        let promise = CircService.placeHold(authtoken: authtoken, userID: userID, recordID: recordID, pickupOrgID: pickupOrg.id, notifyByEmail: emailSwitch.isOn, notifySMSNumber: notifyPhoneNumber, smsCarrierID: notifyCarrierID)
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
}
