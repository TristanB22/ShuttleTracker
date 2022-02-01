import Foundation
import UIKit
import StoreKit
import CoreLocation


class SettingsView: UIViewController {
        
    @IBOutlet weak var DriverStatusButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        if(isDriver){
            DriverStatusButton.setTitle("Turn off Driver mode", for: .normal)
        }else{
            DriverStatusButton.setTitle("Sign into Driver", for: .normal)
        }
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "v" + appVersion
        }
    }
    
    @IBAction func BackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SelectAppIcon1(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-1")
    }
    
    @IBAction func SelectAppIcon2(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-2") //Unused
    }
    
    @IBAction func SelectAppIcon3(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-3")
    }
    
    @IBAction func SelectAppIcon4(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-4")
    }

    @IBAction func SelectAppIcon5(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-5")
    }
    
    @IBAction func RateTheApp(_ sender: Any) {
        SKStoreReviewController.requestReview()
    }
    
    @IBAction func OurWebsite(_ sender: Any) {
        let urlString = "http://henhen1227.com/sps-bus-tracker/index.php"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }else{
            let alertController = UIAlertController(title: "Couldn't connect", message: "The servers may be down, sorry for the inconvenience", preferredStyle: .alert)
            let close = UIAlertAction(title: "Close", style: .cancel) { (action) -> Void in
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(close)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func BusDriverSignIn(_ sender: Any) {
        if !isDriver {
            // Declare Alert message
            let dialogMessage = UIAlertController(title: "Sign in", message: "", preferredStyle: .alert)

            dialogMessage.addTextField(configurationHandler: { textField in
                textField.placeholder = "Enter password"
            })
           // Create OK button with action handler
           let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
               if (dialogMessage.textFields![0] as UITextField).text == "P"//Filled with the password, but not provided on Github, sorry
               {
                   if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                       isTracking = true
                       isDriver = true
                       UserDefaults.standard.setValue(true, forKey: "isTracking")
                       UserDefaults.standard.setValue(true, forKey: "isDriver")
                   }
               }
               DispatchQueue.main.async {
                   self.performSegue(withIdentifier: "CloseSettingsView", sender:self)
               }
           })
           
           // Create Cancel button with action handlder
           let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
               self.dismiss(animated: true, completion: nil)
           }
           
            dialogMessage.addAction(ok)
            dialogMessage.addAction(cancel)
            self.present(dialogMessage, animated: true, completion: nil)
        }else{
            isDriver = false
            isTracking = false
            
            UserDefaults.standard.setValue(false, forKey: "isTracking")
            UserDefaults.standard.setValue(false, forKey: "isDriver")
            
            self.performSegue(withIdentifier: "CloseSettingsView", sender:self)
        }
        
    }
    
    
}

class IconNames: ObservableObject {
    var iconNames: [String?] = [nil]
    @Published var currentIndex = 0
    
    init() {
        getAlternateIconNames()
        
        if let currentIcon = UIApplication.shared.alternateIconName{
            self.currentIndex = iconNames.firstIndex(of: currentIcon) ?? 0
        }
    }
        
    func getAlternateIconNames(){
            if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                let alternateIcons = icons["CFBundleAlternateIcons"] as? [String: Any]
            {
                     
                 for (_, value) in alternateIcons{

                     guard let iconList = value as? Dictionary<String,Any> else{return}
                     guard let iconFiles = iconList["CFBundleIconFiles"] as? [String]
                         else{return}
                         
                     guard let icon = iconFiles.first else{return}
                     iconNames.append(icon)
        
                 }
            }
    }
}
