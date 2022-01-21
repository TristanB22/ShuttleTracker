import Foundation
import UIKit
import StoreKit


class SettingsView: UIViewController {
    
    
    @IBAction func BackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SelectAppIcon1(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-1")
    }
    
    @IBAction func SelectAppIcon2(_ sender: Any) {
        UIApplication.shared.setAlternateIconName("AppIcon-2")
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
