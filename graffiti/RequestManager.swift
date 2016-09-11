//
//  RequestManager.swift
//  graffiti
//
//  Created by Varun Sayal on 9/10/16.
//  Copyright © 2016 ___varun___. All rights reserved.
//


import Darwin
import UIKit
import CoreLocation
import CoreMotion

class RequestManager: NSObject,CLLocationManagerDelegate {
    
    var config : NSURLSessionConfiguration?
    var session: NSURLSession?
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    
    var lat : CLLocationDegrees?
    var long: CLLocationDegrees?
    var direction: CLLocationDirection?
    var attitude: CMAttitude?
    
    class var sharedInstance : RequestManager {
        struct Static {
            static var token : dispatch_once_t = 0
            static var sharedInstance : RequestManager? = nil
        }
        
        dispatch_once(&Static.token) {
            Static.sharedInstance = RequestManager()
        }
        return Static.sharedInstance!
    }
    
    override init() {
        super.init()
        config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config!)
        
        // Get in use gps permissions
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        self.motionManager.deviceMotionUpdateInterval = 0.1
        
        self.motionManager.startDeviceMotionUpdatesToQueue(
            NSOperationQueue.currentQueue()!, withHandler: {
                (deviceMotion, error) -> Void in
                
                if(error == nil) {
                    self.attitude = deviceMotion?.attitude
                } else {
                    //handle the error
                }
        })
        
        self.direction = 15.0
        self.lat = self.locationManager.location!.coordinate.latitude
        self.long = self.locationManager.location!.coordinate.longitude
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.lat = locValue.latitude
        self.long = locValue.longitude
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.direction = newHeading.magneticHeading
    }
    
    func getPopulatedUrlComponents(path: String) -> NSURLComponents
    {
        // Set up base URL
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "varunsayal.com"
        urlComponents.port = 5000
        urlComponents.path = path
        
        // Create list of url components
        
        
        print("lat = \(self.lat!), long = \(self.long!), direction = \(self.direction!), aptitude = \(self.attitude!.pitch)")

        
        let latQuery = NSURLQueryItem(name: "lat", value: String(self.lat!))
        let longQuery = NSURLQueryItem(name: "long", value: String(self.long!))
        let directionQuery = NSURLQueryItem(name: "direction", value: String(self.direction!))
        let orientationQuery = NSURLQueryItem(name: "orientation", value: String(self.attitude!.pitch))
        
        urlComponents.queryItems = [latQuery, longQuery, directionQuery, orientationQuery]

        return urlComponents
    }
    
    func vote(id: Int32, up: Bool)
    {
        // Set up base URL
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "varunsayal.com"
        urlComponents.port = 5000
        if(up){
            urlComponents.path = "/upvote"
        }else{
            urlComponents.path = "/downvote"
        }
        
        let idQuery = NSURLQueryItem(name: "id", value: String(id))
        urlComponents.queryItems = [idQuery]
        
        guard let upvoteUrl = urlComponents.URL else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = NSURLRequest(URL: upvoteUrl)
        let task = self.session!.dataTaskWithRequest(urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                return
            }
            
        }
        
        task.resume()
        
    }
    
    func getDoodles(action: (doodle: Doodle) -> Void, semaphore: dispatch_semaphore_t) {
        
        let urlComponents : NSURLComponents = getPopulatedUrlComponents("/doodle")
        
        if (urlComponents.queryItems == nil) // Never setup params
        {
            dispatch_semaphore_signal(semaphore)
        }
        
        guard let getDoodlesUrl = urlComponents.URL else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = NSURLRequest(URL: getDoodlesUrl)
        let task = self.session!.dataTaskWithRequest(urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }

            do{
                let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: .AllowFragments)
                
                let entries = json["entries"]
                
                for entry in entries as! [Dictionary<String, AnyObject>]
                {
                    let doodleID = entry["id"]
                    let payload = entry["payload"]
                    
                    guard let decodedData = NSData(base64EncodedString: String(payload), options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters) else{
                        print("Error: Decoding from base64")
                        return
                    }
                    
                    let headeroffset = 6 // constant 6 bytes are prepended to payload
                    let realDecodedData = NSData(bytes: decodedData.bytes+headeroffset, length:decodedData.length-headeroffset)
                    
                    if let image = UIImage(data: realDecodedData, scale: 1.0)
                    {
                        action(doodle: Doodle(id: Int32(String(doodleID!))!, image: image))
                    }else{
                        print("Error: Could not make image")
                    }

                }
            }catch{
                print("Error making to json: \(error)")
            }
            
            dispatch_semaphore_signal(semaphore)
            
        }
        task.resume()
    }
    
    func tagDoodle(imageInView: UIImage){
        
        let urlComponents : NSURLComponents = getPopulatedUrlComponents("/tag")
        
        if (urlComponents.queryItems == nil) // Never setup params
        {
            return
        }
        
        guard let tagUrl = urlComponents.URL else {
            print("Error: cannot create URL")
            return
        }
        
        let doodleRequest = NSMutableURLRequest(URL: tagUrl)
        doodleRequest.HTTPMethod = "POST"
        
        doodleRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        doodleRequest.HTTPBody = UIImagePNGRepresentation(imageInView)
        
        let task = self.session!.dataTaskWithRequest(doodleRequest) {
            (data, response, error) in
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            guard error == nil else {
                print("error calling POST on /todos/1")
                print(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                print(responseData)
            })
        }
        task.resume()
    }


}
