/*
 * Copyright (c) 2023 Kenneth H. Cox
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

class MessageDetailsViewController : UIViewController {

    var message: PatronMessage?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

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
        self.setupHomeButton()
        let button = UIBarButtonItem(image: UIImage(named: "mark_email_unread"), style: .plain, target: self, action: #selector(markUnreadButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(button)

        titleLabel.text = message?.title
        dateLabel.text = message?.createDateLabel
        bodyLabel.text = message?.message.trim()
    }

    func fetchData() {
        guard let account = App.account,
              let authtoken = account.authtoken else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        guard let messageID = message?.id else { return }

        // mark message read
        ActorService.markMessageRead(authtoken: authtoken, messageID: messageID).done {
            // nada
        }.catch { error in
            self.presentGatewayAlert(forError: error, title: "Error marking message read")
        }
    }

    @objc func markUnreadButtonPressed(sender: UIBarButtonItem) {
        guard let account = App.account,
              let authtoken = account.authtoken else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        guard let messageID = message?.id else { return }

        // mark message unread
        ActorService.markMessageUnread(authtoken: authtoken, messageID: messageID).done {
            self.navigationController?.popViewController(animated: true)
        }.catch { error in
            self.presentGatewayAlert(forError: error, title: "Error marking message unread")
        }
    }
}
