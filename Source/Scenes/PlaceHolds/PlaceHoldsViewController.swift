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
    let formats = Format.getSpinnerLabels()
    var orgLabels = ["Attleboro Public Library", "Boston Public Library", "Marlboro Public Library"]

    @IBOutlet weak var holdsTitleLabel: UILabel!
    
    @IBOutlet weak var locationPicker: McTextField!
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationPicker()
//        setupViews()
//        fetchData()
    }
    
    func setupLocationPicker() {
//        self.orgLabels = Organization.getSpinnerLabels()
        let mcInputView = McPicker(data: [orgLabels])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        mcInputView.fontSize = 16
        locationPicker.text = orgLabels[0] //TODO: better initial value
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak locationPicker] (selections) in
            locationPicker?.text = selections[0]!
        }
    }

}
