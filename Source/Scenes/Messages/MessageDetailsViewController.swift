//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import UIKit

class MessageDetailsViewController: UIViewController {

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

        Task { await self.fetchData() }
    }

    //MARK: - Functions

    func setupViews() {
        self.setupHomeButton()
        let image = loadAssetImage(named: "mark_email_unread")
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(markUnreadButtonPressed(sender:)))
        button.accessibilityLabel = "Mark message unread"
        navigationItem.rightBarButtonItems?.append(button)

        titleLabel.text = message?.title
        dateLabel.text = message?.createDateLabel
        bodyLabel.text = message?.message.trim()
    }

    @MainActor
    func fetchData() async {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        guard let messageID = message?.id else { return }

        do {
            try await App.svc.user.markMessageRead(account: account, messageID: messageID)
        } catch {
            self.presentGatewayAlert(forError: error, title: "Error marking message read")
        }
    }

    @MainActor
    func markMessageUnread(account: Account, messageID: Int) async {
        do {
            try await App.svc.user.markMessageUnread(account: account, messageID: messageID)

        } catch {
            self.presentGatewayAlert(forError: error, title: "Error marking message unread")
        }
    }

    @objc func markUnreadButtonPressed(sender: UIBarButtonItem) {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        guard let messageID = message?.id else { return }

        Task { await markMessageUnread(account: account, messageID: messageID) }
    }
}
