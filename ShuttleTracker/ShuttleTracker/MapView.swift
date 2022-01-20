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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, GADBannerViewDelegate {

    var schoolPoint = CustomIcon()
    var busPoint = CustomIcon()
    var userPoint = CustomIcon()
    var targetPoint = CustomIcon()
    var marketbasketPoint = CustomIcon()
    var capitalPoint = CustomIcon()
    var BusPath = MKPolyline()
    
    
    var bannerView: GAMBannerView!

    let locationManager = CLLocationManager()
    
    let localRegion = MKCoordinateRegion.init(center: CLLocationCoordinate2D.init(latitude: 43.19, longitude: -71.552), span: MKCoordinateSpan.init(latitudeDelta: 0.063, longitudeDelta: 0.063))
    
    var ref: DatabaseReference!
    var timeRef: DatabaseReference!
    
    @IBOutlet weak var MapView: MKMapView!
    
    //MARK: Sidebar
    var sidebarIsShown = false
    @IBOutlet weak var MenuSideView: UIView!
    @IBOutlet weak var menuView: menuIcon!
    
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
        
        MenuSideView.frame = CGRect(x: -75, y: 0, width: 70, height: self.MapView.frame.height)
        mainFrame = view.frame
        
        //Testing Connection:
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if (snapshot.value as? Bool)! {
                print("Connected")
            } else {
                print("Not connected")
            }
        })
        
        ref = Database.database().reference().child("Bus")
        timeRef = Database.database().reference().child("TimeStamp")
//        timeRef = Database.database().reference().child("Bus")

        /// `.childAdded` is a short way of writting `DataEventType.childAdded` because the expected type is `DataEventType`, Just like any other type such as `Int`,`String`and`Bool`
        ref.observe(.childAdded, with: { (snapshot) -> Void in
            self.handleSnapshot(snapshot: snapshot)
        })
        ref.observe(.childChanged, with: { (snapshot) -> Void in
            self.handleSnapshot(snapshot: snapshot)
        })
        
        timeRef.observe(.childAdded, with: { (snapshot) -> Void in
            self.handleSnapshot(snapshot: snapshot)
        })
        timeRef.observe(.childChanged, with: { (snapshot) -> Void in
            self.handleSnapshot(snapshot: snapshot)
        })
//        ref.observe(.childChanged, with: { (snapshot) -> Void in
//            self.handleSnapshot(snapshot: snapshot)
//        })
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.updateDistanceText()
        })
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            ///Could Also use `kCLLocationAccuracyBestForNavigation` but would also then use excess cellular
            locationManager.startUpdatingLocation()
        }

        
        bannerView = GAMBannerView(adSize: GADAdSizeBanner)
        
        bannerView.adUnitID = "ca-app-pub-8518185967716817/5711807395" // Code for actual ads
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111" // Test Ads
        
        bannerView.delegate = self
        bannerView.rootViewController = self
        bannerView.load(GAMRequest())
        addBannerViewToView(bannerView)
        
        ToggleMenu()
    }
    
    //MARK: Bus Data Updated
    func updateBusLocation(){
        //Change Depending on the Ardunio's method of saving the data
        busPoint.coordinate = pastBusLocations[0]
        
        MapView.removeOverlays(MapView.overlays)
        
//        BusPath = MKPolyline(coordinates: pastBusLocations, count: pastBusLocations.count)
//        MapView.addOverlay(BusPath)
        if(pastBusLocations.count > 3){
            for i in 0...pastBusLocations.count-2 {
                BusPath = gradientPolyline(locations: pastBusLocations, index: i)
                MapView.addOverlay(BusPath)
            }
        }
        
        updateDistanceText()
    }
    
    //MARK: View Rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
//                print("Portrait")
                mainFrame = CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: size)
                sidebarIsShown = false
                ToggleMenu()
        }
    //
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
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
            print(routePolyline.pointCount)
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.lineWidth = 4
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent((routePolyline.distance!)/1.35)
//            renderer.strokeColor = UIColor.blue.withAlphaComponent(0.9)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0{
            guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
            
            userPoint.coordinate = CLLocationCoordinate2D.init(latitude: locValue.latitude, longitude: locValue.longitude)
        }
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
    
    @IBAction func Info(_ sender: Any) {
        
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
    
    func handleSnapshot(snapshot: DataSnapshot){
        print(snapshot)
        if snapshot.exists() {
            if(snapshot.key == "Bus"){
                let busData = snapshot.value as! String
                pastBusLocations.removeAll()
                for coordSet in busData.split(separator: "*") {
                    let data = coordSet.split(separator: ",")
                    pastBusLocations.append(CLLocationCoordinate2D.init(latitude: CLLocationDegrees(Double(data[0])!), longitude: Double(data[1])!))
                    print(data)
                }
                self.updateBusLocation()
            }else if snapshot.key == "time"{
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
class gradientPolyline: MKPolyline {
    var distance: CGFloat?
    convenience init(locations: [CLLocationCoordinate2D], index: Int) {
            self.init(coordinates: [locations[index], locations[index+1]], count: 2)
        distance = CGFloat(Float(locations.count - index)/Float(locations.count))
    }
}
