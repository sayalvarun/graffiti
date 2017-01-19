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
    
    private static var __once: () = {
            Static.sharedInstance = RequestManager()
        }()
    
    var config : URLSessionConfiguration?
    var session: URLSession?
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    
    var lat : CLLocationDegrees?
    var long: CLLocationDegrees?
    var direction: CLLocationDirection?
    var attitude: CMAttitude?
    
    struct Static {
        static var token : Int = 0
        static var sharedInstance : RequestManager? = nil
    }
    
    class var sharedInstance : RequestManager {
        _ = RequestManager.__once
        return Static.sharedInstance!
    }
    
    override init() {
        super.init()
        config = URLSessionConfiguration.default
        session = URLSession(configuration: config!)
        
        // Get in use gps permissions
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        self.motionManager.deviceMotionUpdateInterval = 0.1
        
        self.motionManager.startDeviceMotionUpdates(
            to: OperationQueue.current!, withHandler: {
                (deviceMotion, error) -> Void in
                
                if(error == nil) {
                    self.attitude = deviceMotion?.attitude
                } else {
                    self.attitude = nil
                    print("Error: Could not get attitude")
                    //handle the error
                }
        })
        
        self.direction = 15.0
        self.lat = 10.0
        self.long = 10.0
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.lat = locValue.latitude
        self.long = locValue.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.direction = newHeading.magneticHeading
    }
    
    func getPopulatedUrlComponents(_ path: String) -> URLComponents
    {
        // Set up base URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "104.236.238.240"
        urlComponents.port = 5000
        urlComponents.path = path
        
        // Create list of url components
        
        
        print("lat = \(self.lat!), long = \(self.long!), direction = \(self.direction!),")// aptitude = \(self.attitude!.pitch)")

        
        let latQuery = URLQueryItem(name: "lat", value: String(self.lat!))
        let longQuery = URLQueryItem(name: "long", value: String(self.long!))
        let directionQuery = URLQueryItem(name: "direction", value: String(self.direction!))
        let orientationQuery = URLQueryItem(name: "orientation", value: String(self.attitude!.pitch))
        
        urlComponents.queryItems = [latQuery, longQuery, directionQuery, orientationQuery]

        return urlComponents
    }
    
    func vote(_ id: Int32, up: Bool)
    {
        // Set up base URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "104.236.238.240"
        urlComponents.port = 5000
        if(up){
            urlComponents.path = "/upvote"
        }else{
            urlComponents.path = "/downvote"
        }
        
        let idQuery = URLQueryItem(name: "id", value: String(id))
        urlComponents.queryItems = [idQuery]
        
        guard let upvoteUrl = urlComponents.url else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = URLRequest(url: upvoteUrl)
        let task = self.session!.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                return
            }
            
        }) 
        
        task.resume()
        
    }
    
    func getDoodles(_ action: @escaping (_ doodle: Doodle) -> Void, semaphore: DispatchSemaphore) {
        
        let urlComponents : URLComponents = getPopulatedUrlComponents("/doodle")
        
        if (urlComponents.queryItems == nil) // Never setup params
        {
            semaphore.signal()
        }
        
        guard let getDoodlesUrl = urlComponents.url else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = URLRequest(url: getDoodlesUrl)
        let task = self.session!.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error ?? "error")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }

            do{
                let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments)  as! [String:AnyObject]
                
                let entries = json["entries"]
                
                for entry in entries as! [Dictionary<String, AnyObject>]
                {
                    let doodleID = entry["id"]
                    let payload = entry["payload"]
                    
                    guard let decodedData = Data(base64Encoded: String(describing: payload), options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else{
                        print("Error: Decoding from base64")
                        return
                    }
                    
                    let headeroffset = 6 // constant 6 bytes are prepended to payload
                    let realDecodedData = Data(bytes: UnsafePointer<UInt8>((decodedData as NSData).bytes.assumingMemoryBound(to: UInt8.self)+headeroffset), count:decodedData.count-headeroffset)
                    
                    if let image = UIImage(data: realDecodedData, scale: 1.0)
                    {
                        action(Doodle(id: Int32(String(describing: doodleID!))!, image: image))
                    }else{
                        print("Error: Could not make image")
                    }

                }
            }catch{
                print("Error making to json: \(error)")
            }
            
            semaphore.signal()
            
        }) 
        task.resume()
    }
    
    func tagDoodle(_ imageInView: UIImage){
        
        let urlComponents : URLComponents = getPopulatedUrlComponents("/tag")
        
        if (urlComponents.queryItems == nil) // Never setup params
        {
            return
        }
        
        guard let tagUrl = urlComponents.url else {
            print("Error: cannot create URL")
            return
        }
        
        let doodleRequest = NSMutableURLRequest(url: tagUrl)
        doodleRequest.httpMethod = "POST"
        
        doodleRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        doodleRequest.httpBody = UIImagePNGRepresentation(imageInView)
        
        let task = self.session!.dataTask(with: doodleRequest as URLRequest, completionHandler: {
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
            
            DispatchQueue.main.async(execute: {
                print(responseData)
            })
        }) 
        task.resume()
    }


}
