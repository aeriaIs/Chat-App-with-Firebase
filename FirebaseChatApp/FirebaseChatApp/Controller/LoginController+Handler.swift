//
//  LoginController+Handler.swift
//  FirebaseChatApp
//
//  Created by sarkom-1 on 06/05/19.
//  Copyright © 2019 Aerials. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

extension LoginController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    @objc func handleLoginRegisterChange() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        //change the height of inputContainer
        inputConstrainViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        
        //change height of nameTextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTF.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        nameTF.isHidden = loginRegisterSegmentedControl.selectedSegmentIndex == 0
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTF.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTF.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
    }
    @objc func handleProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        self.present(picker, animated: true, completion: nil)
    }
    @objc func handleLoginRegisterButton() {
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    func handleLogin() {
        guard let email = emailTF.text, let password = passwordTF.text else {
            print("Form Isnt valid")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                print(error ?? "")
                return
            }
            print("Sueccessfully Login with User")
            self.messageController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        }
    }
    func handleRegister() {
        guard let email = emailTF.text, let password = passwordTF.text, let name = nameTF.text else {
            print("Form Isnt valid")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            //Successfully authenticated user
            guard let uid = result?.user.uid else {
                return
            }
            
            let imageName = UUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            if let profileImage = self.profileImageView.image, let uploadData = profileImage.jpegData(compressionQuality: 0.1) {
                storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    storageRef.downloadURL(completion: { (url, err) in
                        if let err = err {
                            print(err)
                            return
                        }
                        //get value profileImageUrl
                        guard let url = url else { return }
                        let values = ["name": name, "email": email, "profileImageUrl": url.absoluteString]
                        self.registerUserIntoDatabaseWithUID(uid, values: values as [String: AnyObject])
                    })
                })
            }
        }
    }
    
    fileprivate func registerUserIntoDatabaseWithUID(_ uid: String, values: [String : AnyObject]) {
        let ref = Database.database().reference()
        let userReference = ref.child("user").child(uid)
        
        userReference.updateChildValues(values) { (err,ref) in
            if err != nil {
                print(err!)
                return
            }
            let user = User(dictionary: values)
            self.messageController?.setupNavBarWithUser(user)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey : Any]) -> [String : Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue,value)})
}
