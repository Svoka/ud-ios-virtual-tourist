//
//  AlertExtension.swift
//  VirtualTourist
//
//  Created by Artem Osipov on 11/04/2020.
//  Copyright © 2020 Artem Osipov. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(alertMessage: AlertMessage, buttonTitle: String, presenter: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertMessage.title, message: alertMessage.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            presenter.present(alert, animated: true)
        }
    }
    
    func getAlertDataFromError(error: ApiClient.ApiError) -> AlertMessage {
        switch error {
        case .networkError:
            return AlertMessage(title: "Network error", message: "Please, try again later")
        case .decodingError:
            return AlertMessage(title: "Decoding error", message: "Please, contact developer or try again later")

        }
    }
}


struct AlertMessage {
    var title: String
    var message: String
}
