//
//  BarCodeViewController.swift
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

import UIKit
import PromiseKit
import ZXingObjC

class ShowCardViewController: UIViewController {
    
    @IBOutlet weak var barCodeImage: UIImageView!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var splashImage: UIImageView!
    
    var didCompleteFetch = false
    let imageWidth: Int32 = 400
    let imageHeight: Int32 = 200

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didCompleteFetch {
            fetchData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupSplash()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        setupSplash()
        //setupBarcode(Barcode.defaultValue(format: App.config.barcodeDisplayFormat))
        self.setupHomeButton()
    }
    
    func setupSplash() {        
        // hide splash in landscape so it doesn't obscure the barcode
        splashImage.isHidden = UIDevice.current.orientation.isLandscape
    }

    func setupBarcode(_ barcode: String) {
        var matrix: ZXBitMatrix? = nil
        matrix = BarcodeUtils.tryEncode(barcode, width: imageWidth, height: imageHeight, format: .Codabar)
        if matrix == nil {
            matrix = BarcodeUtils.tryEncode(barcode, width: imageWidth, height: imageHeight, format: .Code39)
        }
        if let m = matrix,
            let cgimage = ZXImage(matrix: m).cgimage
        {
            barcodeLabel.text = BarcodeUtils.displayLabel(barcode, format: App.config.barcodeFormat)
            barCodeImage.image = UIImage(cgImage: cgimage)
        } else {
            barcodeLabel.text = "Invalid barcode: \(barcode)"
            barCodeImage.image = UIImage(named: "invalid_barcode")
        }
    }

    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }

        let promise = ActorService.fetchUserSettings(account: account)
        promise.done {
            if let barcode = account.barcode {
                self.setupBarcode(barcode)
                self.didCompleteFetch = true
            }
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
}

