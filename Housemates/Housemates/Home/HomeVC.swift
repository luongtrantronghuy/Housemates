//
//  HomeViewController.swift
//  Housemates
//
//  Created by Jackson Tran on 4/26/22.
//

import UIKit

// Your Home VC if user is part of a house
class HomeVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var choresView: UIView!
    @IBOutlet weak var currentChoreLabel: UILabel!
    
    @IBOutlet var choreNextButton: UIButton!
    @IBOutlet weak var choreTableView: UITableView!
    @IBOutlet weak var ruleTableView: UITableView!
    @IBOutlet var rulesView: UIView!
    @IBOutlet var ruleTitleLabel: UILabel!
    @IBOutlet var addRuleButton: UIButton!

    var choreList = [chore]()
    var approvedRuleList = [rule]()
    var unapprovedRuleList = [rule]()
    var toDateFormatter = DateFormatter()
    var printDateFormatter = DateFormatter()
    var loaded = 0
    let loadingIndicator: ProgressView = {
        let progress = ProgressView(colors: [UIColor.init(red:65/255, green: 125/255, blue: 122/255, alpha: 1)], lineWidth: 5)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up progress loading view
        overrideUserInterfaceStyle = .light
        self.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 50),
            loadingIndicator.heightAnchor.constraint(equalTo: self.loadingIndicator.widthAnchor)
        ])
        
        loadingIndicator.isAnimating = true

        // Set up UI design
        setBottomBorder(label: currentChoreLabel, height: 8, color: UIColor.white.cgColor)
        setBottomBorder(label: ruleTitleLabel, height: 8, color: UIColor.init(red:65/255, green: 125/255, blue: 122/255, alpha: 1).cgColor)
        
        choresView.layer.cornerRadius = 13
        choresView.layer.shadowColor = UIColor.black.cgColor
        choresView.layer.shadowOpacity = 0.5
        choresView.layer.shadowOffset = .zero
        choresView.layer.shadowRadius = 10
        choresView.isHidden = true
        
        // Set up delegates and datasource for tableview
        ruleTableView.delegate = self
        ruleTableView.dataSource = self
        choreTableView.delegate = self
        choreTableView.dataSource = self
        
        ruleTableView.estimatedRowHeight = 100
        ruleTableView.rowHeight = UITableView.automaticDimension
        
        choreTableView.estimatedRowHeight = 100
        choreTableView.rowHeight = UITableView.automaticDimension
        
        rulesView.layer.cornerRadius = 13
        rulesView.layer.shadowColor = UIColor.black.cgColor
        rulesView.layer.shadowOpacity = 0.3
        rulesView.layer.shadowOffset = .zero
        rulesView.layer.shadowRadius = 10
        rulesView.isHidden = true
        ruleTableView.layer.cornerRadius = 13

        
        addRuleButton.layer.cornerRadius = 40/2
        addRuleButton.layer.zPosition = 3
        
        // Set up date formatting
        toDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        printDateFormatter.dateStyle = DateFormatter.Style.long
        printDateFormatter.timeStyle = DateFormatter.Style.short
    }
    
    // Checks if all data is done async loading (gets all data from server)
    func doneLoading() {
        if loaded == 3 {
            loadingIndicator.isAnimating = false
            self.sortChoreList()
            self.choreTableView.reloadData()
            self.ruleTableView.reloadData()
            self.rulesView.isHidden = false
            self.choresView.isHidden = false
            self.loaded = 0
        }
    }
    
    // Gets data when view will appear
    override func viewWillAppear(_ animated: Bool) {
        getApprovedRules()
        getUserUnvotedRules()
        
        getChoreByUser(userID: String(currentUser!.id))
    }
    
    // Find rule either from unpprovedRule or approvedRule
    func findRuleWithIndex(index: Int) -> rule {
        if index < unapprovedRuleList.count {
            return unapprovedRuleList[index]
        } else {
            return approvedRuleList[index - unapprovedRuleList.count]
        }
    }
    
    // Returns number of row for respective tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case choreTableView:
            return choreList.count
        case ruleTableView:
            return approvedRuleList.count + unapprovedRuleList.count
        default:
            return 0
        }
    }
    
    // Deque cell for each row base on specified tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case choreTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "YourChoreCell") as! YourChoreCell
            let chore = choreList[indexPath.row] as chore
            let dateFromString: Date? = toDateFormatter.date(from: chore.due_date)
            cell.choreTitle.text = chore.name
            cell.choreDescription.text = chore.description
            cell.choreTime.text = printDateFormatter.string(from: dateFromString!)
            return cell
        case ruleTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RuleCell") as! RuleCell
            let rule = findRuleWithIndex(index: indexPath.row)
            
            if indexPath.row < unapprovedRuleList.count {
                cell.approveButton.isHidden = false
                cell.unapproveButton.isHidden = false
            } else {
                cell.approveButton.isHidden = true
                cell.unapproveButton.isHidden = true
            }
            cell.ruleTitle.text = rule.title
            cell.ruleDescription.text = rule.description
            cell.rule = rule
            cell.parentVC = self
            return cell
        default:
            return UITableViewCell()
        
        }
    }
    
    // Responds to selecting a row based on tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case choreTableView:
            performSegue(withIdentifier: "seguePickChore", sender: indexPath)
            return
        case ruleTableView:
            return
        default:
            return
        
        }
        
    }
    
    // Preparation for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seguePickChore" {
            let destinationVC = segue.destination as! ChoreHalfSheetVC
            destinationVC.sheetPresentationController?.detents = [.medium(), .large()]
            let indexPath = sender as! IndexPath
            let chore = choreList[indexPath.row] as chore
            destinationVC.chore = chore
            destinationVC.parentVC = self
        } else if segue.identifier == "segueAddChores" {
            let destinationVC = segue.destination as! AddChoresVC
            destinationVC.parentVC = self
            destinationVC.isEditting = true
            if let choreData = sender as? (chore: chore, assignees: [user]) {
                destinationVC.choreData = choreData
            }
        } else if segue.identifier == "segueAddRule" {
            let destinationVC = segue.destination as! AddRuleVC
            destinationVC.sheetPresentationController?.detents = [.medium()]
            destinationVC.parentVC = self
        }
    }
    
    // Segues to see all Chores
    @IBAction func onChoreNext(_ sender: Any) {
        performSegue(withIdentifier: "segueAllChore", sender: nil)
    }
    
    // Segue view member (side bar)
    @IBAction func onViewMembers(_ sender: Any) {
        self.tabBarController?.performSegue(withIdentifier: "segueMembers", sender: nil)
    }
    
    // Segue to add rule
    @IBAction func onAddRule(_ sender: Any) {
        performSegue(withIdentifier: "segueAddRule", sender: nil)
    }
    
    // Sort chore list based on date
    func sortChoreList() {
        self.choreList.sort(by: {toDateFormatter.date(from: $0.due_date)!.compare(toDateFormatter.date(from: $1.due_date)!) == .orderedAscending})
    }
    
    // Request chores by userID
    func getChoreByUser(userID: String) {
        var components = URLComponents(string: "http://127.0.0.1:8080/get_chores_by_user")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID)
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var request = URLRequest(url: components.url!)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "GET"
        
        let dataTask = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            var result:choreResponse
            do {
                guard let data = data else {
                    print("Server not connected!")
                    return
                }
                result = try JSONDecoder().decode(choreResponse.self, from: data)
                self.choreList = result.data  ?? []
                DispatchQueue.main.async {
                    self.loaded += 1
                    self.doneLoading()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    // Get approved rules from a house
    func getApprovedRules(){
        var components = URLComponents(string: "http://127.0.0.1:8080/get_approved_house_rules")!
        components.queryItems = [
            URLQueryItem(name: "house_code", value: String(currentUser!.house_code!))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var request = URLRequest(url: components.url!)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            var result:ruleResponse
            do {
                guard let data = data else {
                    print("Server not connected!")
                    return
                }
                
                result = try JSONDecoder().decode(ruleResponse.self, from: data)
                
                self.approvedRuleList = result.data ?? []
                DispatchQueue.main.async {
                    self.loaded += 1
                    self.doneLoading()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    // Get unapprovedrules from a house
    func getUnapprovedRules(){
        var components = URLComponents(string: "http://127.0.0.1:8080/get_not_approved_house_rules")!
        components.queryItems = [
            URLQueryItem(name: "house_code", value: String(currentUser!.house_code!))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var request = URLRequest(url: components.url!)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            var result:ruleResponse
            do {
                guard let data = data else {
                    print("Server not connected!")
                    return
                }
                
                result = try JSONDecoder().decode(ruleResponse.self, from: data)
                
                self.unapprovedRuleList = result.data ?? []
                DispatchQueue.main.async {
                    self.loaded += 1
                    self.doneLoading()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    //Get user unvoted rules from unapproved rules
    func getUserUnvotedRules(){
        var components = URLComponents(string: "http://127.0.0.1:8080/get_unvoted_house_rules")!
        components.queryItems = [
            URLQueryItem(name: "house_code", value: String(currentUser!.house_code!)),
            URLQueryItem(name: "user_id", value: String(currentUser!.id))
        ]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var request = URLRequest(url: components.url!)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            var result:ruleResponse
            do {
                guard let data = data else {
                    print("Server not connected!")
                    return
                }
                
                result = try JSONDecoder().decode(ruleResponse.self, from: data)
                self.unapprovedRuleList = result.data ?? []
                DispatchQueue.main.async {
                    self.loaded += 1
                    self.doneLoading()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
    }
}

