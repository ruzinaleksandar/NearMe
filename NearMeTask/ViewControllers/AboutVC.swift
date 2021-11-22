//
//  AboutVC.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//

/*
 
 About us view controller that contains static text which is set when the view controller is loaded
 
 */

import UIKit

class AboutVC: UIViewController {
    
    @IBOutlet var logoImage: UIImageView!
    @IBOutlet var appName: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var credits: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        logoImage.image = UIImage(named: "AppLogo")
        appName.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String // getting the Display name key from the app's main bundle
        subtitle.text = "mentormate iOS coding challenge" 
        credits.text = "Candidate: Aleksandar Ruzin\nruzin.aleksandar@gmail.com"
    }

}
