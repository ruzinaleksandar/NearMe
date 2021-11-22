//
//  ViewController.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 19.11.21.
//

/*
 
 The first viewcontroller shown in the application that has the UISegmentedControl and a container view that is used for showing the list of nearby venues and the "About" screen. Changing the value of the UISegmentedControl changes the loaded view controller in the container view
 
 */

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var refreshVenuesButton: UIBarButtonItem!
    
    lazy var nearMeVC : NearMeVC = { //lazy loading the NearMe view controller
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var vc = storyboard.instantiateViewController(withIdentifier: Constants.nearMeVcIdentifier) as! NearMeVC
        self.addChild(vc)
        return vc
    }()
    
    lazy var aboutVC : AboutVC = { // lazy loading the About view controller
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var vc = storyboard.instantiateViewController(withIdentifier: Constants.aboutVcIdentifier) as! AboutVC
        self.addChild(vc)
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.selectedSegmentIndex = 0 //setting up the selected value of the UISegmentControll
        segmentedControl.sendActions(for: .valueChanged) // manually invoking the value changed action on the UISegmentControl for loading the initial content of the container view
    }
    
    @IBAction func didChangeSegment(sender: UISegmentedControl) { //handling the value change in the UISegmentedControl
        let oldVC = children.first!
        switch sender.selectedSegmentIndex {
        case 0:
            cycle(from: oldVC, to: nearMeVC)
        default:
            cycle(from: oldVC, to: aboutVC)
        }
    }
    
    func cycle(from oldVC: UIViewController, to newVC: UIViewController) {
        //custom function that replaces the content of the container view and handles the tansition with animation from the old content to the new content
        oldVC.willMove(toParent: nil)
        addChild(newVC)
        newVC.view.frame = containerView.bounds
        transition(from: oldVC, to: newVC, duration: 0.1, options: .transitionCrossDissolve, animations: {}, completion: {finished in
            oldVC.removeFromParent()
            newVC.didMove(toParent: self)
        })
    }

    @IBAction func didTapRefreshVenues(_ sender: Any) { // handles the tap on the right bar button
        nearMeVC.refreshVenueData() //invokes the refreshVenueData dunction in the Nera Me View Controller
    }
}
