//
//  ArtworkInBuildingTableViewController.swift
//  ArtworksOnCampus
//
//  Created by Haoxuan Wang on 06/12/2017.
//  Copyright © 2017 Haoxuan Wang. All rights reserved.
//

import UIKit
import CoreData

class ArtworkInBuildingViewController: UIViewController, UITableViewDelegate,UITableViewDataSource{
    
    var buildingArtsMap: Dictionary<Building, [ArtWork]>?
    var currentBuilding: Building?
    @IBOutlet weak var navBarItem: UINavigationItem!
    
    @IBAction func backToMain(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBarItem.title = currentBuilding!.name
    }
    
    // set up tables
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (buildingArtsMap![currentBuilding!]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: String(indexPath.row)+"rowCell")
        let artsWork = buildingArtsMap![currentBuilding!]![indexPath.row]
        cell.textLabel?.text = artsWork.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetails", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails"{
            if sender is IndexPath{
                let vc = segue.destination as! DetailsViewController
                let index = sender as! IndexPath
                vc.item = buildingArtsMap?[currentBuilding!]![index.row]
                vc.currentBuilding = currentBuilding!
            }
        }
    }
    
    
    
}
