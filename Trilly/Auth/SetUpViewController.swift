//
//  SetUpViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 9/28/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import Modals3A
import UIKit
import MBProgressHUD
import Firebase
import MaterialTB

class SetUpViewController: UIViewController, UITextFieldDelegate, DatePickerDelegate, OptionPickerDelegate{
    
    
    @IBOutlet weak var profileContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var mailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var birthField: UITextField!
    @IBOutlet weak var genreField: UITextField!
    @IBOutlet weak var doneB: UIButton!
    @IBOutlet weak var text: UILabel!
    
    let gender_options = ["Masculino", "Femenino", "Otro"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboards = [nameField, mailField, phoneField, birthField, genreField]
        setUpSmartKeyboard()
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        self.text.textColor = Trilly.UI.mainColor
        self.doneB.backgroundColor = Trilly.UI.mainColor
        
        if let user = User.current {
            if let url = user.photo {
                self.profileImageView.downloadedFrom(link: url)
            }
            self.nameField.text = user.name
            if let mail = user.email {
                self.mailField.text = mail
                self.mailField.isEnabled = false
            }
            self.phoneField.text = user.phone
            if user.birth != nil {
                self.birthField.text = (user.birth! as Date).toString(format: .Short)
            }
            self.genreField.text = gender_options[user.gender ?? 2]
        }
        
        MBProgressHUD.hide(for: self.view, animated: true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        profileContainer.roundCorners(radius: profileContainer.bounds.size.width/2)
        doneB.addNormalShadow()
        doneB.roundCorners(radius: Trilly.UI.roundPx)
        
        self.originalFrame = self.view.bounds
    }
    
    @IBAction func selectProfilePicture(_ sender: UIButton) {
       // Load image picker
    }
    
    @IBAction func done(_ sender: Any) {
        let mb = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        guard nameField.text != "" else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(title: "¡Espera!", message: "Debes ingresar tu nombre", closeButtonTitle: "Entendido")
            return
        }
        
        guard (nameField.text!.characters.count) <= 50 else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(title: "¡Espera!", message: "El nombre que has ingresado es muy largo.", closeButtonTitle: "Entendido")
            return
            
        }
        
        guard mailField.text != "" && mailField.text!.contains("@") && mailField.text!.contains(".") && !mailField.text!.contains("+") && mailField.text!.characters.count <= 100 else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(title: "¡Espera!", message: "Debes ingresar un correo válido", closeButtonTitle: "Entendido")
            return
        }
        
        guard (phoneField.text?.characters.count)! == 10 else {
            MBProgressHUD.hide(for: self.view, animated: true)
            showAlert(title: "¡Espera!", message: "El número celular que has ingresado no es válido", closeButtonTitle: "Entendido")
            return
        }
        
        if birthField.text == "" {
            birthField.text = Date().toString(format: .Custom("dd-MM-yyyy"))
        }
        
        if genreField.text == "" {
            genreField.text = "Otro"
        }
        
        mb.label.text = "Guardando tu información"
        let profile_picture_ref = Trilly.Database.storageRef().child("users/\(User.current!.uid!)/profile_picture.jpg")
        guard let pp_data = UIImageJPEGRepresentation(self.profileImageView.image!, 0.8) else {
            self.showAlert(title: "Lo sentimos", message: "Ha ocurrido un error al subir tu foto a nuestra nube. Intenta de nuevo.", closeButtonTitle: "Ok")
            return
        }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        mb.label.text = "Subiendo foto"
        
        let _ = profile_picture_ref.putData(pp_data, metadata: metaData) { (metadata, error) in
            guard let metadata = metadata else {
                mb.hide(animated: true)
                self.showAlert(title: "Lo sentimos", message: "Ha ocurrido un error al subir tu foto a nuestra nube. Intenta de nuevo.", closeButtonTitle: "Ok")
                return
            }
            
            let downloadURL = metadata.downloadURL()
            if let photo = downloadURL?.absoluteString {
                User.current!.photo = photo
                
                mb.label.text = "Finalizando"
                
                if let local = Auth.auth().currentUser {
                    let req = local.createProfileChangeRequest()
                    if local.displayName != self.nameField.text {
                        req.displayName = self.nameField.text
                    }
                    req.commitChanges(completion: nil)
                }
                
                User.current!.name = self.nameField.text
                User.current!.email = self.mailField.text
                User.current!.phone = self.phoneField.text
                User.current!.birth = Date(fromString: self.birthField.text!)! as NSDate
                User.current!.joined = NSDate()
                User.current!.nextTree = 0
                User.current!.blocked = false
                User.current!.gender = self.gender_options.index(of: self.genreField.text!)
                
                User.current!.save()
                
                mb.hide(animated: true)
                
                MaterialTB.currentTabBar!.reloadViewController()
                
            } else {
                mb.hide(animated: true)
                self.showAlert(title: "Lo sentimos", message: "Ha ocurrido un error al subir tu foto a nuestra nube. Intenta de nuevo.", closeButtonTitle: "Ok")
                return
            }
            
        }
        
        MaterialTB.currentTabBar!.reloadViewController()
    }
    
    // ImagePicker Delegate
    
    // DatePicker Delegate
    func didPickDate3A(date: Date, string:String, tag:Int) {
        self.birthField.text = string
    }
    
    // OptionPicker Delegate
    func didPickSingleOption3A(index:Int, selected:String, tag:Int) {
        self.genreField.text = selected
    }
    
    // UI Helpers
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 1:
            self.needsDisplacement = CGFloat(0)
            return true
        case 2:
            self.needsDisplacement = CGFloat(1)
            return true
        case 3:
            self.needsDisplacement = CGFloat(1)
            return true
        case 4:
            // Date Picker
            self.clearKeyboards()
            Modals3A.datePickerWith(title: "¿Qué día naciste?", date: self.birthField.text, to: .now, onViewController: self)
            return false
        case 5:
            // Gender Picker
            self.clearKeyboards()
            if let sel = self.genreField.text {
                if let ind = gender_options.index(of: sel) {
                    Modals3A.optionPickerWith(title: "Género", options: gender_options, onViewController: self, selected: [ind])
                } else {
                    Modals3A.optionPickerWith(title: "Género", options: gender_options, onViewController: self)
                }
            } else {
                Modals3A.optionPickerWith(title: "Género", options: gender_options, onViewController: self)
            }
            
            return false
        default:
            return true
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 5:
            textField.resignFirstResponder()
            return true
        default:
            textField.resignFirstResponder()
            self.view.viewWithTag(textField.tag+1)?.becomeFirstResponder()
            return true
        }
    }
}
