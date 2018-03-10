//
//  ViewController.swift
//  ArtworksOnCamous
//
//  Created by Haoxuan Wang on 01/12/2017.
//  Copyright © 2017 Haoxuan Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreData

/* Globally Shared data structures*/
// They are loaded only once when the application launches.
// To avoid reload so make it globally

// Building - ArtWork 1 to many map, fetch when first loading
var buildingArtsMap = Dictionary<Building, [ArtWork]>()
// MkPointAnnotation - Building 1 to 1 map,setted when first loading
var buildingNotationMap = Dictionary<MKPointAnnotation, Building>()

// Sorted array according to current position
var sortedBuildingArtsTuple = [(Building,[ArtWork])]()

//mark to check whether requires initialisation (i.e. download / updata data and load data to maps above)
var isInLaunch = true

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,MKMapViewDelegate,CLLocationManagerDelegate {
    
    var baseURL = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate="
    
    // Set up table in main View Controller
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedBuildingArtsTuple.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedBuildingArtsTuple[section].0.name
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedBuildingArtsTuple[section].1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell( withIdentifier: "ArtCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier:  "ArtCell")
        }
        let building = sortedBuildingArtsTuple[indexPath.section].0
        if buildingArtsMap[building] != nil{
            cell?.textLabel?.text = buildingArtsMap[building]![indexPath.row].title
            cell?.detailTextLabel?.text = String(Int((locationManager.location?.distance(from: CLLocation(latitude: building.latitude, longitude: building.longtitude)))!))+" m"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toDetail" , sender: indexPath)
        
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var map: MKMapView!
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up loactionManager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // If it the first time to the view (i.e. launching process)
        if isInLaunch {
            
            // fetch the last date... Incremental update
            let defaults = UserDefaults.standard
            let lastRun = defaults.string(forKey: "LastRunDay")
            if lastRun != nil {
                print(lastRun!)
                baseURL = baseURL + lastRun!
            }
            print(baseURL)
            
            // download, parse and storage data
            let group = DispatchGroup()
            group.enter()
            parseJSON(baseURL,
                      finished: {artworks in
                        CoreDataHandler.store(artworks)
                        defaults.set(Date().string(with: "yyyy-MM-dd"), forKey: "LastRunDay")
                        group.leave()
            })
            
            //set up data structure
            group.notify(queue: .main) {
                
                let storedBuildings = CoreDataHandler.fetchAllBuildings()
                
                for building in storedBuildings {
                    
                    buildingArtsMap[building] = [ArtWork]()
                    let artsHere = building.owns?.allObjects as! [ArtWork]
                    
                    // enable only "enabled" item, which means support deletions
                    
                    buildingArtsMap[building]?.append(contentsOf: artsHere.filter({$0.enabled}))
                    
                    if buildingArtsMap[building]!.count>0{
                        let annotation = self.makeAnnotation(on: self.map, building: building,itemsMap: buildingArtsMap)
                        buildingNotationMap[annotation] = building
                    }else{
                        buildingArtsMap.removeValue(forKey: building)
                    }
                    
                }
                sortedBuildingArtsTuple = buildingArtsMap.sorted(by:{self.locationManager.location!.distance(from: CLLocation(latitude: $0.0.latitude, longitude: $0.0.longtitude))<self.locationManager.location!.distance(from: CLLocation(latitude: $1.0.latitude, longitude: $1.0.longtitude))})
                self.tableView.reloadData()
            }
            
            // mark next time do not require initialisation
            isInLaunch = false
            
        }else{
            // add annotation
            for annotation in buildingNotationMap.keys {
                self.map.addAnnotation(annotation)
            }
            
            // reload table data
            self.tableView.reloadData()
        }
        
    }
    
    
    // handle click on annotations of the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKPointAnnotation{
            let annotation = view.annotation as! MKPointAnnotation
            let building = buildingNotationMap[annotation]
            if buildingArtsMap[building!]!.count > 1{
                self.performSegue(withIdentifier: "toMultiple", sender: annotation)
            }else{
                self.performSegue(withIdentifier: "toDetail", sender: annotation)
            }
            
        }
    }
    
    //method for set up an annotation on map
    func makeAnnotation(on map: MKMapView, building:Building, itemsMap:Dictionary<Building, [ArtWork]>)->MKPointAnnotation{
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(exactly: building.latitude)
        let long = CLLocationDegrees(exactly: building.longtitude)
        let coordination = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
        annotation.coordinate = coordination
        if (itemsMap[building] != nil), itemsMap[building]!.count>1{
            annotation.title = building.name
        }else{
            if itemsMap[building] != nil{
                annotation.title = itemsMap[building]![0].title
            }
        }
        self.map.addAnnotation(annotation)
        return annotation
    }
    
    // method for jump to other controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // jump to the art work details' controller
        if segue.identifier == "toDetail" {
            // handle clicking from table view
            if sender is IndexPath{
                var index = sender as! IndexPath
                let dest = segue.destination as! DetailsViewController
                let building = sortedBuildingArtsTuple[index.section].0
                dest.item = buildingArtsMap[building]?[index.row]
                dest.currentBuilding = building
            }
            //handle clicking from map view
            if sender is MKPointAnnotation {
                let annotation = sender as! MKPointAnnotation
                let building = buildingNotationMap[annotation]
                let dest = segue.destination as! DetailsViewController
                dest.item = buildingArtsMap[building!]?[0]
                dest.currentBuilding = building!
            }
        }
        // jump to the list of multiple art works
        if segue.identifier == "toMultiple"{
            if sender is MKPointAnnotation {
                let annotation = sender as! MKPointAnnotation
                let building = buildingNotationMap[annotation]
                let dest = segue.destination as! ArtworkInBuildingViewController
                dest.buildingArtsMap = buildingArtsMap
                dest.currentBuilding = building!
            }
        }
        
    }
    
    // actions when user locations changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.0014, longitudeDelta: 0.0014)
        let region = MKCoordinateRegion(center: location, span: span)
        self.map.setRegion(region, animated: true)
        
        sortedBuildingArtsTuple = buildingArtsMap.sorted(by:{locations[0].distance(from: CLLocation(latitude: $0.0.latitude, longitude: $0.0.longtitude))<locations[0].distance(from: CLLocation(latitude: $1.0.latitude, longitude: $1.0.longtitude))})
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

