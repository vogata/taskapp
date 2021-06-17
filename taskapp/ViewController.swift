//
//  ViewController.swift
//  taskapp
//
//  Created by KAZUKI-OGATA on 2021/06/14.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var inputCategory: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    var searchTasks: Results<Task>!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchByKeyword(keyword: "")
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @objc func dismissKeyboard() {
        // close keyboard
        view.endEditing(true)
    }

    func searchByKeyword(keyword: String) {
        searchTasks = taskArray.filter(NSPredicate(format: "category = %@", keyword))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        if(segue.identifier == "cellSegue"){
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = searchTasks[indexPath!.row]
        }else{
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if(allTasks.count != 0){
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func searchCategory(_ sender: Any) {
        dismissKeyboard()
        searchByKeyword(keyword: inputCategory.text ?? "")
        tableView.reloadData()
      }
    
    // count of items for tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return searchTasks.count
    }

    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let task = searchTasks[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }

    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }

    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.searchTasks[indexPath.row]
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            // delete from DB
            try! realm.write{
                self.realm.delete(self.searchTasks[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
}
