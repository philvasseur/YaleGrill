//
//  ViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    //Page for logging in. Doesn't do much besides try to auto login. Contains the GIDSignIn button.
    /*
     Method for googleSign in. Is called when you press the button and when the application loads. Checks if there is authentication in keychain cached, if so checks if a yale email. If it has a yale email then moves to OrderScreen page with active orders. If not a yale email then logs out.
     */
    var pickerDataSource = FirebaseConstants.PickerData

    @IBOutlet weak var diningHallTextField: UITextField!
    //@IBOutlet weak var PickerView: UIPickerView!
    @IBOutlet weak var LoadingImage: UIImageView!
    @IBOutlet weak var LoadingBack: UIImageView!
    @IBOutlet weak var GSignInButton: GIDSignInButton!
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        /* check for user's token */
        let selectedDiningHall = diningHallTextField.text
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            print("\(GIDSignIn.sharedInstance().currentUser.profile.email!) TRYING TO SIGN IN - AUTH")
            let cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
            if(cEmail.lowercased().range(of: "@yale") != nil){ //Checks if email is a Yale email
                guard let authentication = user.authentication else { return }
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    if let error = error {
                        print("Firebase Auth Error: \(error)")
                        return
                    }
                    if(selectedDiningHall=="Select Dining Hall"){
                        let dHallRef = FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(FirebaseConstants.prevDining)
                        dHallRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                            let pastDHall = snapshot.value as? String
                            if(pastDHall != nil){
                                self.diningHallTextField.text = pastDHall
                                self.performSegue(withIdentifier: FirebaseConstants.SignInSegueID, sender: nil)
                            }else{
                                GIDSignIn.sharedInstance().signOut()
                                self.createAlert(title: "Sorry!", message: "Please select a dining hall!")
                                print("No Accessible Dining Hall")
                                self.LoadingBack.isHidden=true
                                self.LoadingImage.isHidden=true
                            }
                        })
                    }else{
                        let dHallRef = FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(FirebaseConstants.prevDining)
                        dHallRef.setValue(selectedDiningHall)
                        self.performSegue(withIdentifier: FirebaseConstants.SignInSegueID, sender: nil)
                    }
                }
            }else if(FirebaseConstants.CookEmailArray.contains(cEmail.lowercased())){
                guard let authentication = user.authentication else { return }
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    if let error = error {
                        print("Firebase Auth Error: \(error)")
                        return
                    }
                    self.performSegue(withIdentifier: FirebaseConstants.ControlScreenSegueID, sender: nil)
            }
            }else{ //Not a yale email, so signs user out.
                print("Non-Yale Email, LOGGING OUT")
                GIDSignIn.sharedInstance().signOut()
                createAlert(title: "Sorry!", message: "You must use a Yale email address to sign in!")
            }
        }else if(error != nil){
            print("Sign In Error: \(error)")
            LoadingBack.isHidden=true
            LoadingImage.isHidden=true
        }else{
            LoadingBack.isHidden=true
            LoadingImage.isHidden=true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier==FirebaseConstants.SignInSegueID){
            let destinationNav = segue.destination as! UINavigationController
            let destinationVC = destinationNav.viewControllers.first as! OrderScreen
            destinationVC.selectedDiningHall = self.diningHallTextField.text
        }
    }
    
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.diningHallTextField.text=pickerDataSource[row]
        if(FirebaseConstants.GrillIDS[pickerDataSource[row]] != nil){
            GSignInButton.isEnabled=true
        }else{
            GSignInButton.isEnabled=false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let pickerView = UIPickerView()
        pickerView.showsSelectionIndicator = true
        pickerView.dataSource = self
        pickerView.delegate = self
        diningHallTextField.inputView = pickerView
        GSignInButton.isEnabled=false
        self.diningHallTextField.text = "Select Dining Hall"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

