import UIKit

class TableViewController: UIViewController {
    var table = UITableView()
    var workItem: DispatchWorkItem?
    var a = AutoRefresh()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(table)
        a.start()
        table.frame = view.bounds
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

class AutoRefresh {
    var workItem: DispatchWorkItem?

    func start() {
        stop()
        var item: DispatchWorkItem?

        item = DispatchWorkItem { [weak self] in
            guard let self else { return }

            self.fetchData {
                guard !item!.isCancelled else { return }
                
                print("item done")
                self.stop()
            }
        }
        workItem = item
        DispatchQueue.main.async(execute: item!)
    }
    
    func stop() {
        workItem?.cancel()
        workItem = nil
    }
    
    func fetchData(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            for i in 0...3 {
                print(i)
                Thread.sleep(forTimeInterval: 1)
            }
        }
        DispatchQueue.main.async { completion() }
    }
}

extension TableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.layer.transform = CATransform3DMakeTranslation(0, 50, 0)
        cell.alpha = 0
        UIView.animate(withDuration: 0.4) {
            cell.alpha = 1
        }
        cell.textLabel?.text = "View Controller"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextView = CellViewController()
        self.navigationController?.pushViewController(nextView, animated: true)
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                nextView.text = "Cell View"
                nextView.themeOfPresentation = "Second Line"
            }
                   
        }
        
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        present(collection[indexPath.row].MoveTo, animated: true)
//    }

}
