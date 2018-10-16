//
//  ViewController.swift
//  MetalExample
//
//  Created by cookie on 2018/10/16.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

import UIKit

struct ExampleVC {
    var title: String
    var vc: () -> UIViewController
}

class ViewController: UIViewController {
    private let data: [ExampleVC] = [ExampleVC(title: "MPSScale", vc: { return MPSScaleViewController() })]
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        view.tableFooterView = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "MetalExample"
        view.addSubview(tableView)
        tableView.frame = view.bounds
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description())
        cell?.textLabel?.text = data[indexPath.row].title
        cell?.accessoryType = .disclosureIndicator
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = data[indexPath.row].vc()
        vc.navigationItem.title = data[indexPath.row].title
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

