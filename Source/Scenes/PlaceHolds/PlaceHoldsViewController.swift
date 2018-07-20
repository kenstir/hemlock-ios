//
//  PlaceHoldsViewController.swift
//  Hemlock
//
//  Created by Erik Cox on 7/13/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire

class PlaceHoldsViewController: UIViewController {

    //MARK: - Properties
    var item: MBRecord?
    let formats = Format.getSpinnerLabels()
    var orgLabels : [String] = []
    weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var holdsTitleLabel: UILabel!
    @IBOutlet weak var locationPicker: McTextField!
    @IBOutlet weak var holdsAuthorLabel: UILabel!
    @IBOutlet weak var holdsSMSNumber: UITextField!
    @IBOutlet weak var holdsCarrier: McTextField!
    
    //MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupLocationPicker() //do this within fetchData()
        setupActivityIndicator()
        setupViews()
        fetchData()
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
        locationPicker.text = orgLabels[0] //TODO: better initial value
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak locationPicker] (selections) in
            locationPicker?.text = selections[0]!
        }
    }

    func fetchData() {
        var promises: [Promise<Void>] = []
        
        promises.append(ActorService.fetchOrgTypesArray())
        promises.append(ActorService.fetchOrgTree())
        
        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
            }.done {
                self.setupLocationPicker()
            }.catch { error in
                self.showAlert(error: error)
            }.finally {
                self.activityIndicator.stopAnimating()
        }
    }
    
    func setupViews() {
        holdsTitleLabel.text = item?.title
        holdsAuthorLabel.text = item?.author
    }
}
