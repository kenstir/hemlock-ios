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
    
    @IBOutlet weak var barcodeImage: UIImageView!
    @IBOutlet weak var barcodeWarningLabel: UILabel!
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
        setupBarcodeTapActions()
        self.setupHomeButton()
    }
    
    func setupSplash() {        
        // hide splash in landscape so it doesn't obscure the barcode
        splashImage.isHidden = UIDevice.current.orientation.isLandscape
    }
    
    func setupBarcodeTapActions() {
        barcodeImage.isUserInteractionEnabled = true
        barcodeImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(barcodeTapped)))
        barcodeLabel.isUserInteractionEnabled = true
        barcodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(barcodeTapped)))
    }

    @objc private func barcodeTapped(_ recognizer: UITapGestureRecognizer) {
        guard let barcode = App.account?.barcode else { return }
        UIPasteboard.general.string = barcode
        self.navigationController?.view.makeToast("Barcode copied to clipboard")

    }

//        barcodeImage.addTarget(self, action: #selector(onBarcodeTap(sender:)), for: .touchUpInside)
        //        cell.renewButton.addTarget(self, action: #selector(renewPressed(sender:)), for: .touchUpInside)

    func setupBarcode(_ barcode: String) {
        guard let m = BarcodeUtils.tryEncode(barcode, width: imageWidth, height: imageHeight, formats: [.Codabar, .Code39]),
            m.width > 0 && m.height > 0,
            let cgimage = ZXImage(matrix: m).cgimage else
        {
            barcodeLabel.text = "Invalid barcode: \(barcode)"
            barcodeImage.image = UIImage(named: "invalid_barcode")
            return
        }
        barcodeLabel.text = BarcodeUtils.displayLabel(barcode, format: App.config.barcodeFormat)
        barcodeImage.image = UIImage(cgImage: cgimage)
        barcodeWarningLabel.text = App.behavior.getCustomString("barcode_warning_msg")
    }

    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
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

