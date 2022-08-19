/*
 * ScanBarcodeViewController.swift
 *
 * Copyright (C) 2022 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import UIKit
import PromiseKit
import os.log

class ScanBarcodeViewController : UIViewController {

    let log = OSLog(subsystem: Bundle.appIdentifier, category: "ScanBarcode")
    
    //MARK: - Properties
    
    var barcodeScannedHandler: ((_ barcode: String) -> Void)?

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    //MARK: - Functions
    
    func setupViews() {
//        self.setupHomeButton()
    }
}
