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

class PlaceHoldsViewController: UIViewController {

    //MARK: - Properties
    var record: MBRecord?
    let formats = Format.getSpinnerLabels()
    var orgLabels : [String] = []
    var carrierLabels : [String] = []
    var selectedOrgIndex = 0
    var selectedCarrierIndex = 0

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
        if (sender.isOn) {
            holdsSMSNumber.isUserInteractionEnabled = true
            holdsSMSNumber.becomeFirstResponder()
        } else {
            holdsSMSNumber.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var placeHoldButton: UIButton!
    @IBAction func placeHoldButtonPressed(_ sender: UIButton) {
        self.placeHold()
    }
    
    //MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupLocationPicker() //do this within fetchData()
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
        self.orgLabels = Organization.getSpinnerLabels()
        let mcInputView = McPicker(data: [orgLabels])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        mcInputView.fontSize = 16
        self.selectedOrgIndex = 0 //TODO: better initial value
        locationPicker.text = orgLabels[self.selectedOrgIndex]
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak locationPicker] (selections) in
            locationPicker?.text = selections[0]!
        }
    }
    
    func setupCarrierPicker() {
        self.carrierLabels = SMSCarrier.getSpinnerLabels()
        let mcInputView = McPicker(data: [carrierLabels])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        mcInputView.fontSize = 16
        self.selectedCarrierIndex = 0 //TODO: better initial value
        carrierPicker.text = carrierLabels[self.selectedCarrierIndex]
        carrierPicker.inputViewMcPicker = mcInputView
        carrierPicker.doneHandler = { [weak carrierPicker] (selections) in
            carrierPicker?.text = selections[0]!
        }
    }

    func fetchData() {
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
//        }.finally {
//            self.activityIndicator.stopAnimating()
        }
    }
    
    func fetchOrgDetails() {
        var promises: [Promise<Void>] = []

        promises.append(contentsOf: ActorService.fetchOrgSettings())
        print("xxx2 \(promises.count) promises made")

//        self.activityIndicator.startAnimating()
      
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx2 \(promises.count) promises fulfilled")
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
        Style.styleButton(asInverse: placeHoldButton)
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
            let pickupOrgID = Organization.find(byName: orgLabels[self.selectedOrgIndex])?.id else
        {
            //TODO: analytics
            return
        }
        
        var notifyPhoneNumber: String? = nil
        var notifyCarrierID: Int? = nil
        if smsSwitch.isOn,
            let carrierID = SMSCarrier.find(byName: carrierLabels[self.selectedCarrierIndex])?.id
        {
            guard let phoneNumber = holdsSMSNumber.text,
                phoneNumber.count > 0 else
            {
                self.showAlert(title: "Error", message: "Phone number field cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNumber
            notifyCarrierID = carrierID
        }

        let promise = CircService.placeHold(authtoken: authtoken, userID: userID, recordID: recordID, pickupOrgID: pickupOrgID, notifyByEmail: emailSwitch.isOn, notifySMSNumber: notifyPhoneNumber, smsCarrierID: notifyCarrierID)
        promise.done { obj in
            if let _ = obj.getInt("result") {
                // case 1: result is an Int - hold successful
                self.navigationController?.view.makeToast("Hold successfully placed")
                self.navigationController?.popViewController(animated: true)
                return
            } else if let resultArray = obj.getAny("result") as? [OSRFObject] {
                // case 2: result is an array of ilsevent objects - hold failed
                if let resultObj = resultArray.first,
                    let ilsevent = resultObj.getInt("ilsevent"),
                    let textcode = resultObj.getString("textcode"),
                    let desc = resultObj.getString("desc") {
                    throw GatewayError.event(ilsevent: ilsevent, textcode: textcode, desc: desc)
                }
                throw HemlockError.unexpectedNetworkResponse(String(describing: resultArray))
            } else {
                throw HemlockError.unexpectedNetworkResponse(String(describing: obj.dict))
            }
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
}

extension PlaceHoldsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
