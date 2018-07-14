//
//  ListsViewController.swift
//
//  CircService.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
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
import ToastSwiftFramework

class ListsViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var button1: UIButton!
    
    @IBOutlet weak var button2: UIButton!
    
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet weak var button4: UIButton!
    
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        button1.tag = 1
        button2.tag = 2
        button3.tag = 3
        button4.tag = 4
        Style.styleButton(asPlain: button2)
        Style.styleButton(asOutline: button3)
        Style.styleButton(asInverse: button4)
        
        let disclosure = UITableViewCell()
        disclosure.frame = button1.bounds
        disclosure.accessoryType = .disclosureIndicator
        disclosure.isUserInteractionEnabled = false
        button1.addSubview(disclosure)
    }
    
    func fetchData() {
    }
    
    @IBAction func doStuff(sender: UIButton) {
        self.view.makeToast("button pressed: \(sender.tag)")
        switch sender.tag {
        case 1:
            self.navigationController?.popToRootViewController(animated: true)
        case 2:
            self.navigationController?.setViewControllers([LoginViewController()], animated: true)
        case 3:
            // this results in a LoginVC that has double-width app bar!
            /*
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "Login")
            self.navigationController?.setViewControllers([vc], animated: true)
            */
            
            // this works but has no animation
            let sb = UIStoryboard(name: "Main", bundle: nil)
//            let vc = sb.instantiateViewController(withIdentifier: "Login")
            let vc = sb.instantiateInitialViewController()
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.window?.rootViewController = vc
            }
        default:
            // this works also and also has no animation
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }
}
