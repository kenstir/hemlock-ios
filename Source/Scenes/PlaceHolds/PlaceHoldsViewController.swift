//
//  PlaceHoldsViewController.swift
//  Hemlock
//
//  Created by Erik Cox on 7/13/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation
import UIKit

class PlaceHoldsViewController: UIViewController {

    //MARK: - Properties
    var item: MBRecord?
    var libraryList = ["Attleboro Public Library", "Boston Public Library", "Marlboro Public Library"]
    @IBOutlet weak var holdsTitleLabel: UILabel!
    
    @IBOutlet weak var pickupLibraryTextField: UITextField!
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        createLibraryPicker()
//        setupViews()
//        fetchData()
    }
    
    func createLibraryPicker() {
        let libraryPicker = UIPickerView()
        libraryPicker.delegate = self
        
        pickupLibraryTextField.inputView = libraryPicker
    }
    
    
}

extension PlaceHoldsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return libraryList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return libraryList[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //stuff
    }
    
}
