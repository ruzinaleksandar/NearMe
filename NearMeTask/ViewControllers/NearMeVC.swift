//
//  NearMeVC.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//

/*
 
 Near me view controller that displays a UITableView with custom UITableViewCell that lists the 5 closest venue around the user's location returned by the Foursquare API
 
 */

import UIKit
import CoreLocation
import Network
import CloudKit
import CoreData

class NearMeVC: UIViewController, CLLocationManagerDelegate, NSURLConnectionDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private let monitor = NWPathMonitor()
    private var locationManager: CLLocationManager!
    private var isActiveConnection: Bool = false
    private let queue = DispatchQueue(label: "Connection")
    private var userLocation: CLLocation?
    @IBOutlet var tableView: UITableView!
    var refreshControll = UIRefreshControl()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    lazy var fetchedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Venue.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "distance", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setting up the CLLocationManager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // notify the location delegate that a new location is available when the location changes more than 100 meters
        locationManager.requestWhenInUseAuthorization()
        setUpConnectionMonitor()
        // setup the tableview
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableView.automaticDimension
        // update the content of the tableview when the view controller is loaded
        updateTableContent()
        // adding a pull to refresh controll to the table view
        refreshControll.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControll.addTarget(self, action: #selector(pulledRefreshControl), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControll)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // check if the location permission is granted
        checkLocationServices()
    }
    
    @objc func pulledRefreshControl(sender:AnyObject) { // handle the pull to refresh controll
        refreshVenueData()
    }
    
    //MARK: - Helper Functions
    
    func refreshVenueData() { // try to get the latest venues from the Foursqare API
        if (isActiveConnection) { // check if there is an active internet connection
            if CLLocationManager.locationServicesEnabled() {
                // if the location permission is granted start monitoring the location updates
                self.locationManager.startUpdatingLocation()
            } else {
                //notify the user that location permission is required
                openSettings()
            }
        } else {
            // notify the user that there is no internet connection
            self.showAlertWith(title: "No connection!", message: "This app needs internet to fetch the venues around you. Shown data might be inacurate, connect to the Internet and pull the table to refresh the data.", button: "Ok")
        }
    }
    
    func updateTableContent() {
        do {
            // try to fetch new venue data
            try self.fetchedhResultController.performFetch()
        } catch let error  {
            showAlertWith(title: "Error", message: error.localizedDescription, button: "Ok")
        }
    }
    
    func setUpConnectionMonitor() { // internet connection monitor that notifies the app and the user about the internet connectivity. It shows an alert to the user and tells the app to load the venue data form CoreData
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connected")
                self.isActiveConnection = true
                if CLLocationManager.locationServicesEnabled() {
                    self.locationManager.startUpdatingLocation()
                } else {
                    self.openSettings()
                }
            } else {
                self.locationManager.stopUpdatingLocation()
                print("No connection")
                self.isActiveConnection = false
                self.locationManager.stopUpdatingLocation()
                DispatchQueue.main.async {
                    self.showAlertWith(title: "No connection!", message: "This app needs internet to fetch the venues around you. Shown data might be inacurate, connect to the Internet and pull the table to refresh the data.", button: "Ok")
                    if (self.refreshControll.isRefreshing) {
                        self.refreshControll.endRefreshing()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func showAlertWith(title: String, message: String, button: String, style: UIAlertController.Style = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: button, style: .default) { (action) in
            if (self.refreshControll.isRefreshing) {
                self.refreshControll.endRefreshing()
            }
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func openSettings() { //open the device's settings screen in the application's bundle in order to change it's location settings
        let alertController = UIAlertController(title: "No location access", message: "This app needs access to your location in order to show you the closest venues.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            self.dismiss(animated: true, completion: {
                if let BUNDLE_IDENTIFIER = Bundle.main.bundleIdentifier,
                   let url = URL(string: "\(UIApplication.openSettingsURLString)&path=LOCATION/\(BUNDLE_IDENTIFIER)") {
                    print("url: \(url)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - CoreData Functions
    
    private func createVenueEntity(dictionary: [String: AnyObject]) -> NSManagedObject? { // parse JSON object as Venue entity
        if let venueEntity = NSEntityDescription.insertNewObject(forEntityName: "Venue", into: context) as? Venue {
            let category = dictionary["categories"] as? [[String: AnyObject]]
            if (!category!.isEmpty) {
                venueEntity.category = category?[0]["name"] as? String
                let icon = category![0]["icon"] as? [String: AnyObject]
                var iconLink = icon?["prefix"] as? String
                iconLink!.append("64")
                iconLink!.append(icon?["suffix"] as! String)
                venueEntity.iconLink = iconLink
            }
            venueEntity.name = dictionary["name"] as? String
            let location = dictionary["location"] as? [String: AnyObject]
            venueEntity.distance = (location?["distance"] as? Int16)!
            venueEntity.latitude = (location?["lat"] as? Double)!
            venueEntity.longitude = (location?["lng"] as? Double)!
            let formattedAddress = location?["formattedAddress"] as? [String]
            var address = ""
            for addr in formattedAddress! {
                address.append(addr)
                address.append("\n")
            }
            venueEntity.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            return venueEntity
        }
        return nil
    }
    
    private func saveInCoreDataWith(array: [[String: AnyObject]]) {
        _ = array.map{self.createVenueEntity(dictionary: $0)}
        do {
            try context.save()
        } catch let error {
            print(error)
        }
    }
    
    private func clearData() { //clear CoreData data each time the venue list is updated from the Foursquare API
        do {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Venue.self))
            do {
                let objects  = try context.fetch(fetchRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                try context.save()
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
        }
    }
    
    //MARK: - Location Updates
    
    func checkLocationServices() { // check if the user granted location permission
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                print("notDetermined")
            case .restricted, .denied: // if the user hasn't granted location permmision show an aler with a button to the phone's settings
                openSettings()
                print("No Location allowed")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            @unknown default:
                break
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // when the phone's location is updated try to fetch new venues from the Foursqare's API
        userLocation = locations[0] as CLLocation
        let service = ApiHelper(latitude: (userLocation?.coordinate.latitude)!, longitude: (userLocation?.coordinate.longitude)!)
        service.getDataWith { (result) in
            switch result {
            case .Success(let data): // if the API response is valid parse the data in CoreData
                self.clearData()
                self.saveInCoreDataWith(array: data)
                self.locationManager.stopUpdatingLocation()
                if (self.refreshControll.isRefreshing) {
                    self.refreshControll.endRefreshing()
                }
            case .Error(let message): // if the response isn't valid notify the user
                DispatchQueue.main.async {
                    if (self.refreshControll.isRefreshing) {
                        self.refreshControll.endRefreshing()
                    }
                    self.showAlertWith(title: "No Internet!", message: message, button: "OK")
                }
            }
        }
    }
    
    //MARK: - TableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //notify the tableview's delegate the row count of the tableview, 0 when there is no data, or fetched results count when there are venues saved
        if let count = fetchedhResultController.sections?.first?.numberOfObjects {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //populate the TableView's custom cells with venue entiy data
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.VENUE_CELL_RESTORATION_ID, for: indexPath) as! VenueCell
        if let venue = fetchedhResultController.object(at: indexPath) as? Venue {
            if let url = venue.iconLink { //load the Foursquare's category icon 
                cell.icon.loadImageUsingCacheWithURLString(url, uiImage: UIImage(named: "logo"))
            }
            cell.name.text = venue.name
            cell.category.text = venue.category
            cell.address.text = venue.address
            cell.distance.text = "\(venue.distance) m"
            cell.coordinates.text = "\(venue.latitude), \(venue.longitude)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //making the cell's height dynamic since the length of the API response data might vary in content length
        return UITableView.automaticDimension
    }
}

//MARK: - NSFetchedResultsControllerDelegate Extension

extension NearMeVC: NSFetchedResultsControllerDelegate {
    // notify the tableview's delegate that the rows size should change when inserting and deleting venue data
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
}

