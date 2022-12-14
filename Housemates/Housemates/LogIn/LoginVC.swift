//
//  LoginVC.swift
//  Housemates
//
//  Created by Jackson Tran on 4/18/22.
//

import UIKit
import SwiftUI

class LoginVC: UIViewController, UITextFieldDelegate {

    // OUTLETS
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up delegates and UI design
        signInButton.tintColor = UIColor.init(red:65/255, green: 125/255, blue: 122/255, alpha: 0.5)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        setBottomBorder(textfield: emailTextField)
        setBottomBorder(textfield: passwordTextField)
    }
    
    
    // End text editing when tapping screen other than textfield
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Disable signInButton if emailTextField or passwordTextField is empty
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if (!(emailTextField.text?.count == 0) && !(passwordTextField.text?.count == 0)) {
            signInButton.isUserInteractionEnabled = true
            signInButton.tintColor = UIColor.init(red:65/255, green: 125/255, blue: 122/255, alpha: 1)
        } else {
            signInButton.isUserInteractionEnabled = false
            signInButton.tintColor = UIColor.init(red:65/255, green: 125/255, blue: 122/255, alpha: 0.5)
        }
    }
    
    // Set responder when user presses enter
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            signin(email: emailTextField.text!, password: passwordTextField.text!)
        }
        return true
    }
    
    // Limit character length in textfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text, let rangeOfTextToReplace = Range(range, in: textFieldText) else { return false }
        
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 32
    }

    // User press sign in
    @IBAction func onSignIn(_ sender: Any) {
        signin(email: emailTextField.text!, password: passwordTextField.text!)
        return
    }
    
    // User press create account
    @IBAction func onCreateAccount(_ sender: Any) {
        performSegue(withIdentifier: "segueToSignUp", sender: nil)
    }
    
    // Deals with error sign in
    func errorSignin() {
        let alert = UIAlertController(title: "Incorrect Email or Password", message: "The email or password you entered is incorrect. Please try again.", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    // Deals preparation for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "SignInSegue") {
            currentUser = sender as? user
        }
    }
    
    // Sign In request
    func signin(email: String, password: String) {
        let url = URL(string: "http://127.0.0.1:8080/login")!
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = httpBody
        request.timeoutInterval = 20
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            var result: userResponse
            guard let data = data else {
                print("Server not connected!")
                return
            }
            do {
                result = try JSONDecoder().decode(userResponse.self, from: data)
                
                if (result.code != 200) {
                    DispatchQueue.main.async {
                        self.errorSignin()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "SignInSegue", sender: result.data)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
}

