//
//  ViewController.swift
//  ShuttleTracker
//
//  Created by Henry Abrahamsen on 10/29/21.
//
// For all of those taking on the endeavour of trying to understand my mess below,  🍀 Good Luck 🍀

import UIKit
import MapKit
import QuartzCore
import CoreLocation
import FirebaseCore
import FirebaseDatabase
import GoogleMobileAds

var pastBusLocations = [CLLocationCoordinate2D]()
var busRoute = [CLLocationCoordinate2D]()

enum distanceUnits {
    case meters
    case kilometers
    case feet
    case miles
}

var isDriver = false
var isTracking = false
let lengthOfBusPath = 25

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, GADBannerViewDelegate {

    //Icons on the map
    var schoolPoint = CustomIcon()
    var busPoint = CustomIcon()
    var userPoint = CustomIcon()
    var targetPoint = CustomIcon()
    var marketbasketPoint = CustomIcon()
    var capitalPoint = CustomIcon()
    var BusPath = MKPolyline()
    
    //For Google Ads, currently disabled
//    var bannerView: GAMBannerView!

    let locationManager = CLLocationManager()
    
    //Starting map view and view when "center" button is pressed
    let localRegion = MKCoordinateRegion.init(center: CLLocationCoordinate2D.init(latitude: 43.19, longitude: -71.552), span: MKCoordinateSpan.init(latitudeDelta: 0.063, longitudeDelta: 0.063))
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var MapView: MKMapView!
    
    var sidebarIsShown = false
    @IBOutlet weak var MenuSideView: UIView!
    @IBOutlet weak var menuView: menuIcon!
    
    @IBOutlet weak var StartTrackingButton: UIButton!
    @IBOutlet weak var StopTrackingButton: UIButton!
    
    
    ///Set to `distanceUnits.___`  to what ever the default should be
    var units = distanceUnits.miles
    
    @IBOutlet weak var BusunitLabel: UILabel!
    
    @IBOutlet weak var BusDistance: UILabel!
    @IBOutlet weak var BusUnitLabel: UILabel!
    @IBOutlet weak var SchoolDistance: UILabel!
    @IBOutlet weak var SchoolUnitLabel: UILabel!
    
    @IBOutlet weak var LastUpdateLabel: UILabel!
    
    @IBOutlet weak var AdSubView: UIView!
    
    var mainFrame = CGRect()
    var adFrame = CGRect(x:0, y: 0, width:300, height: 40)
    
    
    //MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        //UserDefaults are Apple's way of saving data after the apps session is closed.
        if(UserDefaults.standard.value(forKey: "isTracking") == nil){
            UserDefaults.standard.setValue(false, forKey: "isTracking")
        }else{
            isTracking = UserDefaults.standard.value(forKey: "isTracking") as! Bool
            if isTracking {
                StartTrackingButton.isHidden = true
                StopTrackingButton.isHidden = false
            }
        }
        
        if(UserDefaults.standard.value(forKey: "isDriver") == nil){
            UserDefaults.standard.setValue(false, forKey: "isDriver")
            
            StartTrackingButton.isHidden = true
            StopTrackingButton.isHidden = true
            isTracking = false
            isDriver = false
        }else{
            isDriver = UserDefaults.standard.value(forKey: "isDriver") as! Bool
        }
        
        
        
        MenuSideView.frame = CGRect(x: -75, y: 0, width: 70, height: self.MapView.frame.height)
        mainFrame = view.frame
        
        //Testing Connection:
        //Always "Not connected" when the app first opens
        //Delay added so that the app has time to connect
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        let delayTime = DispatchTime.now() + 5.0 //After 5 seconds
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            connectedRef.observe(.value, with: { snapshot in
                if (snapshot.value as? Bool)! {
                    print("Connected")
                } else {
                    print("Not connected")
                    
                    let alertController = UIAlertController(title: "Couldn't connect to database", message: "Check your connection and try again", preferredStyle: .alert)
                    let close = UIAlertAction(title: "Close", style: .cancel) { (action) -> Void in
                        self.dismiss(animated: true, completion: nil)
                    }
                    alertController.addAction(close)
                    self.present(alertController, animated: true, completion: nil)
                }
            })
            
            //Also allow it to load the distance and update the text
            self.updateDistanceText()
        })
        
        ref = Database.database().reference().child("TestBus")

        /// `.childAdded` is a short way of writting `DataEventType.childAdded` because the expected type is `DataEventType`, Just like any other type such as `Int`,`String`and`Bool`
        ref.observe(.childAdded, with: { (snapshot) -> Void in
                self.handleSnapshot(snapshot: snapshot)
        })
        ref.observe(.childChanged, with: { (snapshot) -> Void in
                self.handleSnapshot(snapshot: snapshot)
        })
        
        
        locationManager.requestWhenInUseAuthorization()
        
        
        
        MapView.region = localRegion
        
        schoolPoint.coordinate = CLLocationCoordinate2D.init(latitude: 43.1949, longitude: -71.57349769)
        targetPoint.coordinate = CLLocationCoordinate2D.init(latitude: 43.2182287, longitude: -71.4847139)
        marketbasketPoint.coordinate = CLLocationCoordinate2D.init(latitude: 43.2032806, longitude: -71.5327576)
        capitalPoint.coordinate = CLLocationCoordinate2D.init(latitude: 43.20715, longitude: -71.538)
        
        schoolPoint.title = "SPS"
        busPoint.title = "Bus"
        userPoint.title = "You"
        targetPoint.title = "Target"
        marketbasketPoint.title = "Market Basket"
        capitalPoint.title = "State House"
        
        schoolPoint.imageName = "SchoolIcon"
        busPoint.imageName = "BusIcon"
        userPoint.imageName = "UserIcon"
        targetPoint.imageName = "TargetIcon"
        marketbasketPoint.imageName = "MarketBasketIcon"
        capitalPoint.imageName = "CapitalIcon"
        
        MapView.addAnnotation(userPoint)
        MapView.addAnnotation(schoolPoint)
        MapView.addAnnotation(busPoint)
        MapView.addAnnotation(targetPoint)
        MapView.addAnnotation(marketbasketPoint)
        MapView.addAnnotation(capitalPoint)
    
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            //If the user isn't a driver, uses a less accurate measurement to use less data.
            if isDriver {
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            }else {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            }
            locationManager.startUpdatingLocation()
        }


//          Disabled for now

//        bannerView = GAMBannerView(adSize: GADAdSizeBanner)
//        bannerView.adUnitID = "" // Code for actual ads
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111" // Test Ads
//
//        bannerView.delegate = self
//        bannerView.rootViewController = self
//        bannerView.load(GAMRequest())
//        addBannerViewToView(bannerView)
        
        ToggleMenu()
    }
    
    //MARK: Update Bus Location
    func updateBusLocation(){
        if (pastBusLocations.count > 0) {
            busPoint.coordinate = pastBusLocations[pastBusLocations.count-1]
            MapView.removeOverlays(MapView.overlays)
            
            //Loops through each location saved and adds them to the overlay on the map
            for i in 1...pastBusLocations.count-1 {
                //Makes each line a increased distance based on how far down the stack of locations they are, their i value.
                BusPath = gradientPolyline(lineStrength: CGFloat(Float(i+1)/Float(pastBusLocations.count)), start: pastBusLocations[i-1], end: pastBusLocations[i])
                
                MapView.addOverlay(BusPath)
            }
            
            updateDistanceText()
        }
    }
    
    //MARK: View Rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
                mainFrame = CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: size)
                sidebarIsShown = false
                ToggleMenu()
        }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    //MARK: Changed Driver Status
    //Called when Settings view is closed and made a change to the Driver Status
    //This is done with a unwind segue called on the bus driver button in the settings
    @IBAction func UpdateDriverView(segue: UIStoryboardSegue) {
        if(isDriver){
            locationManager.requestAlwaysAuthorization()
            
            //Present Alert when background tracking is not allowed
            switch(CLLocationManager.authorizationStatus()) {
                case .authorizedAlways:
                
                    if(isTracking){
                        StartTrackingButton.isHidden = true
                        StopTrackingButton.isHidden = false
                    }else{
                        StartTrackingButton.isHidden = false
                        StopTrackingButton.isHidden = true
                    }
                
                case .authorizedWhenInUse:
                
                    if(isTracking){
                        StartTrackingButton.isHidden = true
                        StopTrackingButton.isHidden = false
                    }else{
                        StartTrackingButton.isHidden = false
                        StopTrackingButton.isHidden = true
                    }
                //Below is the alert that will be shown when the user isn't allowing their location to be tracked in the background
                let alertController = UIAlertController(title: "Background Tracking Disabled", message: "Please go to Settings and turn on the permissions", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                   guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                       return
                   }
                   if UIApplication.shared.canOpenURL(settingsUrl) {
                       UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)

                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                // Presents the alert with parent view "self" so it is on the current view.
                self.present(alertController, animated: true, completion: nil)
                
                
                case .notDetermined, .restricted, .denied:
                
                    isTracking = false
                    isDriver = false
                    StartTrackingButton.isHidden = true
                    StopTrackingButton.isHidden = true
                
                //Below is the alert that will be shown when the user isn't allowing their location to be tracked in the background
                let alertController = UIAlertController(title: "Location Tracking Disabled", message: "Please go to Settings and turn on the permissions", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                   guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                       return
                   }
                   if UIApplication.shared.canOpenURL(settingsUrl) {
                       UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)

                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                // Presents the alert with parent view "self" so it is on the current view.
                self.present(alertController, animated: true, completion: nil)
                    
                @unknown default:
                    print("Oh no, The location permission is not recognized")
            }
        }else{
            StartTrackingButton.isHidden = true
            StopTrackingButton.isHidden = true
        }
    }
        
    @IBAction func StopTrackingPressed(_ sender: Any) {
        if(isDriver){
            isTracking = false
            UserDefaults.standard.setValue(false, forKey: "isTracking")
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            StartTrackingButton.isHidden = false
            StopTrackingButton.isHidden = true
        }else{
            StartTrackingButton.isHidden = true
            StopTrackingButton.isHidden = true
        }
    }
    
    @IBAction func StartTrackingPressed(_ sender: Any) {
        if(isDriver){
            isTracking = true
            UserDefaults.standard.setValue(true, forKey: "isTracking")
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            
            StartTrackingButton.isHidden = true
            StopTrackingButton.isHidden = false
            
            sendNewBusLocation()
        }else{
            StartTrackingButton.isHidden = true
            StopTrackingButton.isHidden = true
        }
    }
    
}

//MARK: Map Functions
extension MapViewController {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let AnnotaionView = MKAnnotationView()
        if let thisAnnotaion = annotation as? CustomIcon {
            AnnotaionView.image = UIImage.init(named: (thisAnnotaion).imageName)
            AnnotaionView.canShowCallout = true
        }
        return AnnotaionView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? gradientPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.lineWidth = 4
            
            //Makes the lines fade based on "Distance"
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent((routePolyline.distance!)/1.25)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    //MARK: User Location Update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0{
            guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
            
            userPoint.coordinate = locValue
            
            if(isTracking && isDriver){
                sendNewBusLocation()
            }
        }
    }
    
    func sendNewBusLocation(){
        let locValue: CLLocationCoordinate2D = userPoint.coordinate
        //updateRange is the number of decimal places the location is rounded to
        //They are rounded so that duplicate locations aren't sent saving data usage
        let updateRange = 100000.0
        let roundedLocValue = CLLocationCoordinate2D.init(latitude: round(locValue.latitude*updateRange)/updateRange, longitude: round(locValue.longitude*updateRange)/updateRange)
        if(pastBusLocations.isEmpty){
            ref.child("Bus").getData(completion: { (error, snapshot) -> Void in
            let busLocs = (snapshot.value as! [[Double]])
                pastBusLocations = []
                for loc in busLocs {
                    pastBusLocations.append(CLLocationCoordinate2D.init(latitude: loc[0], longitude: loc[1]))
                }
            })
         }else{
             if(pastBusLocations.last!.latitude != roundedLocValue.latitude || pastBusLocations.last!.longitude != roundedLocValue.longitude){
                 var newData = [[Double]]()
                 for loc in pastBusLocations {
                     let thisLoc = [loc.latitude, loc.longitude]
                     newData.append(thisLoc)
                 }
                 while newData.count > 40 {
                     newData.removeFirst()
                 }
                 pastBusLocations.append(roundedLocValue)
                 self.ref.child("Bus").setValue(newData)
             }
        }
        
        let Date = Date()
        let calendar = Calendar.current
        let time = String(format: "%02d",calendar.component(.hour, from: Date)) + ":" + String(format: "%02d", calendar.component(.minute, from: Date)) + ":" + String(format: "%02d",calendar.component(.second, from: Date))
        ref.child("TimeStamp").setValue(time)
        LastUpdateLabel.text = time
        
        if locationManager.desiredAccuracy == kCLLocationAccuracyBestForNavigation {
            sendLocationToServer(loc: locValue, time: time)
        }
        
        updateBusLocation()

    }
    
    //MARK: Save Data to Server
    func sendLocationToServer(loc: CLLocationCoordinate2D, time: String){
        print("requested")

        //Copied from https://stackoverflow.com/questions/37400639/post-data-to-a-php-method-from-swift
        //I understand like none of it lol
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://henhen1227.com/sps-bus-tracker/upload.php")! as URL)
        request.httpMethod = "POST"
        let postString = "loc=\(String(loc.longitude)+","+String(loc.latitude))&time=\(time)"
        print(postString)
        request.httpBody = postString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in

            if error != nil {
                print("error=\(error)")
                return
            }

        print("response = \(String(describing: response))")

        let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("responseString = \(responseString)")
        }
        //The Request was sent and other processes were running async while it was loading so this resumes the sync loading. I think... 😂
        task.resume()
    }
}

//MARK: Side View
extension MapViewController {
    func ToggleMenu(){
        if !sidebarIsShown {
            UIView.animate(withDuration: 0.5, animations: {
                self.MenuSideView.frame = CGRect(x: -self.MenuSideView.frame.width, y: 0, width: self.MenuSideView.frame.width, height: self.MapView.frame.height)
                self.menuView.setFractionOpen(0)
                
                self.AdSubView.frame = CGRect(x: self.mainFrame.midX - self.adFrame.width/2, y: self.mainFrame.maxY  - self.AdSubView.frame.height, width: self.adFrame.width, height:  self.AdSubView.frame.height)
            })
        }else{
            UIView.animate(withDuration: 0.5, animations: {
                self.MenuSideView.frame = CGRect(x: 0, y: 0, width: self.MenuSideView.frame.width, height: self.MapView.frame.height)
                
                self.menuView.setFractionOpen(1)
                
                self.AdSubView.frame = CGRect(x: self.mainFrame.width - self.adFrame.width, y: self.mainFrame.maxY  - self.AdSubView.frame.height, width: self.adFrame.width, height:  self.AdSubView.frame.height)
            })
        }
    }
    
    @IBAction func ToggleMenuView(_ sender: Any) {
        sidebarIsShown = !sidebarIsShown
        ToggleMenu()
    }
    
    @IBAction func Center(_ sender: Any) {
        MapView.setRegion(localRegion, animated: true)
        sidebarIsShown = false
        ToggleMenu()
    }
}

//MARK: Google's Functions
extension MapViewController {
    func addBannerViewToView(_ bannerView: GAMBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        AdSubView.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
              attribute: .bottom,
              relatedBy: .equal,
              toItem: bottomLayoutGuide,
              attribute: .top,
              multiplier: 1,
              constant: 0),
             NSLayoutConstraint(item: bannerView,
              attribute: .right,
              relatedBy: .equal,
              toItem: AdSubView,
              attribute: .right,
              multiplier: 1,
              constant: 0)
      ])
        adFrame = bannerView.frame
    }
    private func bannerViewDidReceiveAd(_ bannerView: GAMBannerView) {
        bannerView.load(GAMRequest())
        addBannerViewToView(bannerView)
    }
    
    //MARK: Handle Snapshots
    func handleSnapshot(snapshot: DataSnapshot){
        if snapshot.exists() {
            if(snapshot.key == "Bus"){
                let busLocs = snapshot.value as! [[Double]]
                pastBusLocations = []
                for loc in busLocs {
                    pastBusLocations.append(CLLocationCoordinate2D.init(latitude: loc[0], longitude: loc[1]))
                }
                self.updateBusLocation()
            }else if snapshot.key == "TimeStamp"{
                LastUpdateLabel.text = snapshot.value as? String;
            }
            
        }
    }
}

//MARK: Change Units
extension MapViewController {
    
    @IBAction func ChangeUnits(_ sender: Any) {
        toggleDistanceUnit()
        updateDistanceText()
    }
    
    func updateDistanceText(){
        let distanceToBusInMeters = distance(a: CLLocation.init(latitude: userPoint.coordinate.latitude, longitude: userPoint.coordinate.longitude), b: CLLocation.init(latitude: busPoint.coordinate.latitude, longitude: busPoint.coordinate.longitude))
        let distanceToSchoolInMeters = distance(a: CLLocation.init(latitude: userPoint.coordinate.latitude, longitude: userPoint.coordinate.longitude), b: CLLocation.init(latitude: schoolPoint.coordinate.latitude, longitude: schoolPoint.coordinate.longitude))
        switch units {
        case .meters:
            BusDistance.text = String(Int(round(distanceToBusInMeters)))
            SchoolDistance.text = String(Int(round(distanceToSchoolInMeters)))
            
            BusUnitLabel.text = "meters"
            SchoolUnitLabel.text = "meters"
        case .kilometers:
            BusDistance.text = String(round(distanceToBusInMeters)/1000)
            SchoolDistance.text = String(round(distanceToSchoolInMeters)/1000)
            
            BusUnitLabel.text = "kilometers"
            SchoolUnitLabel.text = "kilometers"
        case .feet:
            BusDistance.text = String(mToft(m: distanceToBusInMeters))
            SchoolDistance.text = String(mToft(m: distanceToSchoolInMeters))
            
            BusUnitLabel.text = "feet"
            SchoolUnitLabel.text = "feet"
        case .miles:
            BusDistance.text = String(mTomi(m: distanceToBusInMeters))
            SchoolDistance.text = String(mTomi(m: distanceToSchoolInMeters))
            
            BusUnitLabel.text = "miles"
            SchoolUnitLabel.text = "miles"
        }
    }
    func toggleDistanceUnit(){
        switch units {
        case .meters:
            units = .kilometers
        case .kilometers:
            units = .feet
        case .feet:
            units = .miles
        case .miles:
            units = .meters
        }
    }
    
    func distance(a: CLLocation, b: CLLocation) -> Double {
        return a.distance(from: b)
    }
    
    func mToft(m:Double) -> Int {return Int(round(m*3.28084))}
    func mTomi(m:Double) -> Double {return round(m*0.0621371)/100}
    
}

//MARK: Menu Icon
class menuIcon: UIView {
  let imageView: UIImageView = {
    let view = UIImageView(image: UIImage(imageLiteralResourceName: "MenuImage"))
    view.contentMode = .center
      view.frame = CGRect.init(x: 0, y: 0, width: 70, height: 70)
    return view
  }()

  required override init(frame: CGRect) {
    super.init(frame: frame)
      addSubview(imageView)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
      addSubview(imageView)
  }

  func setFractionOpen(_ fraction: CGFloat) {
    let angle = fraction * .pi/2.0
    imageView.transform = CGAffineTransform(rotationAngle: angle)
  }
}

//MARK: Custom Icon
class CustomIcon: MKPointAnnotation {
    var imageName: String!
}

//MARK: Gradient Line
//Added "Distance" varible to measure the amount of alpha the line should be drawn with.
class gradientPolyline: MKPolyline {
    var distance: CGFloat?
    convenience init(lineStrength: CGFloat, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        self.init(coordinates: [start, end], count: 2)
        distance = lineStrength
    }
}

