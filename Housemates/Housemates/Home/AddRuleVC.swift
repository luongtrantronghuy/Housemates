//
//  AddRuleVC.swift
//  Housemates
//
//  Created by Jackson Tran on 5/24/22.
//

import UIKit

class AddRuleVC: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        descriptionTextField.delegate = self
        
        setBottomBorder(textfield: titleTextField)
        
        descriptionTextField.delegate = self
        descriptionTextField.layer.cornerRadius = 13
        descriptionTextField.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if descriptionTextField.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if descriptionTextField.text.isEmpty {
            descriptionTextField.text = "Add a Description"
            descriptionTextField.textColor = UIColor.lightGray
        }
    }
    
    @IBAction func onAdd(_ sender: Any) {
        if titleTextField.text!.isEmpty || descriptionTextField.text!.isEmpty {
            errorAddRule()
        }
        createHouseRules(house_code: currentUser!.house_code! , title: titleTextField.text!, description: descriptionTextField.text!, voted_num: 1)
        
    }
    func errorAddRule() {
        let alert = UIAlertController(title: "Empty Text Field", message: "One or more textfield is empty. Please fill in those textfields.", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func createHouseRules(house_code: String, title: String, description: String, voted_num: Int) {
        let url = URL(string: "http://127.0.0.1:8080/create_house_rules")!
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "house_code": house_code,
            "title": title,
            "description": description,
            "voted_num": String(voted_num)
        ]
        print(parameters)
        
        let httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = httpBody
        request.timeoutInterval = 20

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            var result:postResponse
            do {
                result = try JSONDecoder().decode(postResponse.self, from: data!)
                print(result)
                if result.code != 200 {
                    print(result)
                    return
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
}
