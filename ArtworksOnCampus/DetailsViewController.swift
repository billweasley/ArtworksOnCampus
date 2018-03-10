//
//  DetailsViewController.swift
//  ArtworksOnCampus
//
//  Created by Haoxuan Wang on 06/12/2017.
//  Copyright © 2017 Haoxuan Wang. All rights reserved.
//

import UIKit
import CoreData


class DetailsViewController: UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    @IBOutlet weak var titleItem: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailText: UITextView!
    var item: ArtWork?
    var currentBuilding: Building?
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // aligning for textView of detail information for the time of loading
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        detailText.setContentOffset(CGPoint.zero, animated: false)
    }
    // aligning for textView of detail information for the time of the phone rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {_ in
            self.detailText.setContentOffset(CGPoint.zero, animated: false)
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleItem.title = item?.title
        detailText.textContainerInset = UIEdgeInsetsMake(10, 10, 0, 10)
        detailText.text = item?.info
        
        // try load image from disk
        let image = ImageHandler.loadImgFromDisk(fileName: (item?.fileName)!)
        
        //if the image do not exist on the device, download the image asynchronizedly and set it
        if image == nil {
            ImageHandler.downloadImg(name: (item?.fileName)!, finished: { newImage in
                self.imageView.image = newImage
            })
        }else{
            imageView.image = image
        }
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Set up tables
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell( withIdentifier: "DetailCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier:  "DetailCell")
        }
        switch indexPath.row {
        case 0:
            cell?.textLabel?.text = item?.title
            cell?.detailTextLabel?.text = "Artwork"
            return cell!
        case 1:
            cell?.textLabel?.text = item?.artist
            cell?.detailTextLabel?.text = "Artist"
            return cell!
        case 2:
            cell?.textLabel?.text = item?.yearOfWork
            cell?.detailTextLabel?.text = "Year"
            return cell!
        default:
            return UITableViewCell()
        }
        
    }
    
}
