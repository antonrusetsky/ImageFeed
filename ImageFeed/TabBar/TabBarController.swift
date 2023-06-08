//
//  TabBarController.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 03.06.2023.
//

import UIKit
 
final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .white
        tabBar.barTintColor = .black
        tabBar.isTranslucent = false
        
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil)
            
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil)
        
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
