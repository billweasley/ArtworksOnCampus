//
//  Utils.swift
//  ArtworksOnCampus
//
//  Created by Haoxuan Wang on 05/12/2017.
//  Copyright © 2017 Haoxuan Wang. All rights reserved.
//

import CoreData
import UIKit


//Extension for date to convert Date to String in given format
extension Date {
    func string(with format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

// Codeble protocal used for parse JSON
struct ArtInfo: Codable{
    var id: String?
    var title:String?
    var artist: String?
    var yearOfWork: String?
    var Information:String?
    var lat: String?
    var long: String?
    var location: String?
    var locationNotes: String?
    var fileName: String?
    var lastModified:String?
    var enabled:String?
}

struct ArtInfos: Codable {
    var artworks2: Array<ArtInfo>
}

// Parse method with finish handler...
func parseJSON(_ address : String, finished: @escaping (_ artWorks: [ArtInfo]) -> ()) {
    guard let url = URL(string: address) else{
        print("error in URL")
        return
    }
    let urlRequest = URLRequest(url:url)
    let session = URLSession.shared
    let task = session.dataTask(with: urlRequest, completionHandler:{
        (data, response, error) in
        print("Entered")
        guard error == nil else{
            return
        }
        guard let responseData = data else {
            print("error 1")
            return
        }
        let decoder = JSONDecoder();
        do{
            print("Fetched")
            print(responseData)
            let artworks = try decoder.decode(ArtInfos.self, from: responseData)
            finished(artworks.artworks2)
        }catch let error{
            print(error.localizedDescription)
        }
    })
    task.resume()
}

class ImageHandler{
    
    // Image storage position url
    private static var documentUrl: URL = {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }()
    // Download url
    private static var downloadURLStr = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"
    
    // save image , return true if successful, or false if it is failed to storage
    private static func save(image: UIImage, fileName: String) -> Bool? {
        let fileURL = documentUrl.appendingPathComponent(fileName)
        if let imageData = UIImageJPEGRepresentation(image, 1.0) {
            try? imageData.write(to: fileURL, options: .atomic)
            return true
        }
        print("Error saving image")
        return false
    }
    
    // load image, return image if successful or nil if it is failed
    public static func loadImgFromDisk(fileName: String) -> UIImage? {
        let fileURL = documentUrl.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    // download image and storage the image after a successful download
    public static func downloadImg(name:String, finished: (@escaping(UIImage)->())){
        let urlStrWithFile = downloadURLStr+name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = URL(string: urlStrWithFile)
        print("Start download...")
        if url != nil {
            DispatchQueue.main.async {
                print("Downloading...")
                print(url!.absoluteString)
                let data = try? Data(contentsOf: url!)
                if data != nil {
                    let image = UIImage(data:data!)!
                    if self.save(image: image, fileName: name)!{
                        finished(image)
                        print("Successful store the downloaded image")
                    }else{
                        print("Fails when storing the downloaded image")
                    }
                }else{
                    print("Fails when downloading the image")
                }
                
            }
        }else{
            print("url is nil")
        }
    }
    
}

class CoreDataHandler{
    
    // set up data
    static var appDelegate: AppDelegate?
    static var context: NSManagedObjectContext?
    init(){
        CoreDataHandler.initial()
    }
    private static func initial(){
        guard appDelegate != nil , context != nil else{
            if(Thread.isMainThread){
                appDelegate = UIApplication.shared.delegate as? AppDelegate
                context = appDelegate?.persistentContainer.viewContext
            }else{
                DispatchQueue.main.sync{
                    appDelegate = UIApplication.shared.delegate as? AppDelegate
                    context = appDelegate?.persistentContainer.viewContext
                }
            }
            return
        }
    }
    
    static func stringToDate(_ str: String) -> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: str)
    }
    
    //store a art work info into core data
    static func store(_ artInfos: [ArtInfo]){
        initial()
        for artInfo in artInfos{
            if(isExistingTheArtInfo(artInfo)){
                let artwork = getExistingTheArtInfo(artInfo)
                // Incremental update
                if artwork?.lastModified?.compare(stringToDate(artInfo.lastModified!)!)==ComparisonResult.orderedAscending {
                    let _ = setStoreAnArt(artInfo)
                }
            }else{
                // do not exist, storage it directly
                let _ = setStoreAnArt(artInfo)
            }
            
            do {
                try context?.save()
            } catch let error{
                print(error.localizedDescription)
            }
        }
    }
    
    // internal method to set up a ArtWork (the NSManagedObject type) for storage
    static private func setStoreAnArt(_ artInfo:ArtInfo) -> ArtWork{
        initial()
        let toInsert = NSEntityDescription.insertNewObject(forEntityName: "ArtWork", into: context!) as! ArtWork
        toInsert.artist = artInfo.artist
        toInsert.fileName = artInfo.fileName
        toInsert.id = Int32(artInfo.id!)!
        toInsert.info = artInfo.Information
        toInsert.lastModified = stringToDate(artInfo.lastModified!)
        toInsert.latitude = Double(artInfo.lat!)!
        toInsert.longtitude = Double(artInfo.long!)!
        toInsert.location = artInfo.location
        toInsert.locationNotes = artInfo.locationNotes
        toInsert.title = artInfo.title
        toInsert.yearOfWork = artInfo.yearOfWork
        toInsert.enabled = Int(artInfo.enabled!)! == 1
        var theBuilding = getExistingBuilding(longtitude: toInsert.longtitude, latitude: toInsert.latitude, name: toInsert.location!)
        if theBuilding == nil{
            theBuilding = storeNewBuilding(longtitude: toInsert.longtitude, latitude: toInsert.latitude, name: toInsert.location!)
            do {
                try context?.save()
            } catch let error{
                print(error.localizedDescription)
            }
        }
        
        theBuilding?.addToOwns(toInsert)
        
        do {
            try context?.save()
        } catch let error{
            print(error.localizedDescription)
        }
        return toInsert
    }
    
    
    // basic method for manuplate Core data
    static func getBuildingsAccordingToPredict(_ predict: NSPredicate?, limit: Int?) -> [Building]{
        initial()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Building")
        if predict != nil {
            request.predicate = predict
        }
        if limit != nil {
            request.fetchLimit = limit!
        }
        var res = [Building]()
        do{
            try res = context?.fetch(request) as! [Building]
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return res
    }
    
    // basic method for manuplate Core data
    static func getArtsAccordingToPredict(_ predict: NSPredicate?, limit: Int?) -> [ArtWork]{
        initial()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ArtWork")
        if predict != nil {
            request.predicate = predict
        }
        if limit != nil{
            request.fetchLimit = limit!
        }
        var res: [ArtWork]
        do{
            res = try context?.fetch(request) as! [ArtWork]
            print("in", res.count)
            return res
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return [ArtWork]()
    }
    
    //get a building from given info
    static func getExistingBuilding(longtitude: Double,latitude: Double, name: String)-> Building?{
        initial()
        let predicate = NSPredicate(format: "name == %@", name)
        let results = getBuildingsAccordingToPredict(predicate, limit: 1)
        if (results.count == 0){
            return nil
        }else{
            return results[0]
        }
    }
    
    //store a building inculding the given info
    static func storeNewBuilding(longtitude: Double,latitude: Double, name: String)-> Building?{
        initial()
        if !isExistingTheBuilding(longtitude: longtitude, latitude: latitude, name: name){
            let toInsert = NSEntityDescription.insertNewObject(forEntityName: "Building", into: context!) as! Building
            toInsert.longtitude = longtitude
            toInsert.latitude = latitude
            toInsert.name = name
            do {
                try context?.save()
            } catch let error{
                print("store ",error.localizedDescription)
            }
            return toInsert
        }else{
            return getExistingBuilding(longtitude:longtitude, latitude:latitude, name:name)
        }
        
        
    }
    
    // check if a building existing in the core data
    static func isExistingTheBuilding(longtitude: Double,latitude: Double, name: String) -> Bool{
        initial()
        let predicate = NSPredicate(format: "name == %@", name)
        let results = getBuildingsAccordingToPredict(predicate, limit: nil)
        if(results.count == 0){
            print(latitude,longtitude,"not exist")
            return false
        }else{
            print(latitude,longtitude,"exist")
            return true
        }
        
    }
    // get a Artwork (Core data type) correspoding to the ArtInfo type (Parsed JSON info)
    static func getExistingTheArtInfo(_ artInfo: ArtInfo)-> ArtWork?{
        initial()
        let predicate = NSPredicate(format: "id == %i", Int32(artInfo.id!)!)
        var res = getArtsAccordingToPredict(predicate, limit: 1)
        if(res.count == 0){
            return nil
        }else{
            return res[0]
        }
    }
    
    // check whether a Artwork (Core data type) correspoding to the ArtInfo type (Parsed JSON info) exists in core data
    static func isExistingTheArtInfo(_ artInfo: ArtInfo) -> Bool{
        initial()
        let predicate = NSPredicate(format: "id == %i", Int32(artInfo.id!)!)
        let res = getArtsAccordingToPredict(predicate, limit: 1)
        if(res.count == 0){
            return false
        }else{
            return true
        }
    }
    
    
    // Fetch all artworks for a building
    static func fetchAllArtWorksForBuilding(building: Building) -> [ArtWork]{
        initial()
        let predicate = NSPredicate(format: "location == %@", building.name!)
        return getArtsAccordingToPredict(predicate, limit: nil)
    }
    
    // fetch all buildings
    static func fetchAllBuildings()->[Building]{
        initial()
        return getBuildingsAccordingToPredict(nil, limit: nil)
    }
    
    // fetch all art works
    static func fetchAllArtWorks()->[ArtWork]{
        initial()
        return getArtsAccordingToPredict(nil, limit: nil)
    }
    
}

