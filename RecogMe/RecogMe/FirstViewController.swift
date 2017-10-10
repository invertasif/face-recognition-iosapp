//
//  FirstViewController.swift
//  RecogMe
//
//  Created by Muhammet Uçan on 6.10.2017.
//  Copyright © 2017 Muhammet Uçan. All rights reserved.
//

import UIKit
import Foundation

extension UIImage {
    var highestQualityJPEGNSData:NSData { return UIImageJPEGRepresentation(self, 1.0)! as NSData }
    var highQualityJPEGNSData:NSData    { return UIImageJPEGRepresentation(self, 0.75)! as NSData}
    var mediumQualityJPEGNSData:NSData  { return UIImageJPEGRepresentation(self, 0.5)! as NSData }
    var lowQualityJPEGNSData:NSData     { return UIImageJPEGRepresentation(self, 0.25)! as NSData}
    var lowestQualityJPEGNSData:NSData  { return UIImageJPEGRepresentation(self, 0.0)! as NSData }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var errorPromptField: UILabel!
    let picker = UIImagePickerController()
    var chosenImage:UIImage = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.password.delegate = self
        username.textContentType = UITextContentType("")
        password.textContentType = UITextContentType("")
        picker.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.registerBtnPressed((Any).self)
        self.view.endEditing(true)
        return false
    }
    
    func clearDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.allowsEditing = true
            picker.sourceType = UIImagePickerControllerSourceType.camera
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .front
            picker.modalPresentationStyle = .formSheet
            picker.showsCameraControls = false
            // can be turned to automatic shoot
            present(picker,animated: true,completion: {
                self.picker.takePicture()
            })
        }
        else {
            noCamera()
        }
    }
    
    func noCamera(){
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "Sorry, this device has no camera",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        present(alertVC, animated: true,completion: nil)
    }
    
    func openPhotoLibrary() {
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // add username and password to container
        let hashedPass = password.text?.utf8.md5
        Global.container[username.text!] = hashedPass?.rawValue
        
        let str64 = imageTobase64(image: chosenImage)
        
        
        // make request in order to enrollment of photo
        sendRequest(image: str64, gallery: "MyGallerry", subject: username.text!)
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: false, completion: nil)
    }
    
    func imageTobase64(image: UIImage) -> String {
        var base64String = ""
        let  cim = CIImage(image: image)
        if (cim != nil) {
            let imageData = image.lowQualityJPEGNSData
            base64String = imageData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
        }
        return base64String
    }
    
    @IBAction func registerBtnPressed(_ sender: Any) {
        if (username.text?.isEmpty)! {
            errorPromptField.text = "Username should be filled."
            errorPromptField.isHidden = false
            return
        }
        if (password.text?.isEmpty)! {
            errorPromptField.text = "Password should be filled."
            errorPromptField.isHidden = false
            return
        }
        
        let userIsExists = Global.container.keys.contains { (keys) -> Bool in
            keys as String == username.text!
        }
        if (userIsExists) {
            errorPromptField.text = "Username exists."
            errorPromptField.isHidden = false
            return
        }

        let camaraAlert = UIAlertController(title: "Photo?", message: "Take a photo with camera or choose a photo from Photo Library", preferredStyle: UIAlertControllerStyle.alert)
        
        camaraAlert.addAction(UIAlertAction(title: "Camera", style: .cancel, handler: { (action: UIAlertAction!) in
            self.openCamera()
        }))
        
        camaraAlert.addAction(UIAlertAction(title: "Library", style: .default, handler: { (action: UIAlertAction!) in
            self.openPhotoLibrary()
        }))
        
        present(camaraAlert, animated: true, completion: nil)
    }
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "test"{
            let vc = segue.destination as! LoggedInViewController
            vc.username.text = self.username.text
            //Data has to be a variable name in your RandomViewController
        }
    }
    
    @IBAction func backFromModal(segue: UIStoryboardSegue) {
        // Switch to the second tab (tabs are numbered 0, 1, 2)
        self.tabBarController?.selectedIndex = 1
    }
    
    func sendRequest(image: String, gallery: String, subject: String) {
        /* Configure session, choose between:
         * defaultSessionConfiguration
         * ephemeralSessionConfiguration
         * backgroundSessionConfigurationWithIdentifier:
         And set session-wide properties, such as: HTTPAdditionalHeaders,
         HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
         */
        let sessionConfig = URLSessionConfiguration.default
        
        /* Create session, and optionally set a URLSessionDelegate. */
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        /* Create the Request:
         Enroll (POST https://api.kairos.com/enroll)
         */
        
        guard let URL = URL(string: "https://api.kairos.com/enroll") else {return}
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        
        // Headers
        
        request.addValue("PHPSESSID=o9vg2pbh99sidgj5imfb2krss6", forHTTPHeaderField: "Cookie")
        request.addValue("a5cad8c462c4dca239d717e4b4191455", forHTTPHeaderField: "app_key")
        request.addValue("e00d0538", forHTTPHeaderField: "app_id")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON Body
        
        let bodyObject: [String : Any] = [
            "image": image,
            "gallery_name": "MyGallery",
            "subject_id": subject
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
                print(responseJSON)
                if let responseJSON = responseJSON as? [String: Any] {
                    // response exist, look for response if ok, redirect to other page
                    self.performSegue(withIdentifier: "register", sender: self)
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    

}

