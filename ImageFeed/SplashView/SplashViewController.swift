//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 26.05.2023.
//

import UIKit
import ProgressHUD

class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Services.sharedServices
    private let oauth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private var splashLogo: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createSplashLogo(safeArea: view.safeAreaLayoutGuide)

        if oauth2TokenStorage.token != nil {
            guard let token = oauth2TokenStorage.token else { return }
            fetchProfile(token: token)
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let authViewController = storyBoard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {return}
            authViewController.delegate = self
            authViewController.modalPresentationStyle = .fullScreen
            self.present(authViewController, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
                    assertionFailure("Invalid config")
                    showAlertViewController()
                    return
                }
        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
    }
    
    private func presentAuthViewController() {
        let authVC = AuthViewController()
        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true, completion: nil)
    }
}

extension SplashViewController {
    private func createSplashLogo(safeArea: UILayoutGuide) {
        view.backgroundColor = .black
        splashLogo = UIImageView()
        splashLogo.image = UIImage(named: "splash_screen_logo")
        splashLogo.contentMode = .scaleToFill
        splashLogo.clipsToBounds = true

        splashLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splashLogo)

        NSLayoutConstraint.activate([
            splashLogo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            splashLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor)
             ])
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
        UIBlockingProgressHUD.show()
    }
    
    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success (let token):
                self.fetchProfile(token: token)
            case .failure:
                showAlertViewController()
                break
            }
            UIBlockingProgressHUD.dismiss()
        }
    }
    
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) {[weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success (let result):
                    self.profileImageService.fetchProfileImageURL(username: result.username) { _ in }
                    self.switchToTabBarController()
                case .failure:
                    self.showAlertViewController()
                    break
                }
                UIBlockingProgressHUD.dismiss()
            }
        }
    }

    private func showAlertViewController() {
        let alertVC = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert)
        let action = UIAlertAction(title: "Ок", style: .default)
        alertVC.addAction(action)
        present(alertVC, animated: true)
    }
}
