//
//  LoginViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import Firebase
import MBProgressHUD

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var google: UIButton!
    @IBOutlet weak var fb: UIButton!
    
    
    
    var authCallback: AuthResultCallback?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        // Do any additional setup after loading the view.
        
        authCallback = { (user, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if (error != nil){
                self.showAlert(title: "Lo sentimos", message: "Ha ocurrido un error inesperado. Intenta de nuevo.", closeButtonTitle: "Ok")
                print(error!.localizedDescription)
            }
            else if user != nil{
                User.withID(id: user!.uid, callback: { (client) in
                    if client == nil {
                        User.current = User(user: user!)
                        self.performSegue(withIdentifier: "SetUp", sender: self)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            } else {
                self.showAlert(title: "Lo sentimos", message:"Ha ocurrido un error inesperado.", closeButtonTitle: "Ok")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fb.addNormalShadow()
        google.addNormalShadow()
    }
    
    @IBAction func loginWithFB(_ sender: Any) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let loginButton = FBSDKLoginButton()
        loginButton.delegate = self
        loginButton.sendActions(for: .touchUpInside)
    }
    
    //Handler
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            MBProgressHUD.hide(for: self.view, animated: true)
            self.showAlert(title: "Lo sentimos", message: String(format: "Ha ocurrido un error inesperado: %@", error.localizedDescription), closeButtonTitle: "Ok")
            return
        }
        
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signIn(with: credential, completion: self.authCallback!)
        
    }
    
    /**
     Sent to the delegate when the button was used to logout.
     - Parameter loginButton: The button that was clicked.
     */
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    @IBAction func loginWithGoogle(_ sender: Any) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        GIDSignIn.sharedInstance().delegate = self
        let loginButton = GIDSignInButton()
        loginButton.sendActions(for: .touchUpInside)
    }
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            MBProgressHUD.hide(for: self.view, animated: true)
            self.showAlert(title: "Lo sentimos", message: String(format: "Ha ocurrido un error desconocido: %@", error.localizedDescription), closeButtonTitle: "Ok")
            return
        }
        
        let authentication = user.authentication
        let credential = GoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                       accessToken: (authentication?.accessToken)!)
        
        Auth.auth().signIn(with: credential, completion: self.authCallback!)
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!,
                     withError error: Error?) {
        // Perform any operations when the user disconnects from app here.
        // ...
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
}
