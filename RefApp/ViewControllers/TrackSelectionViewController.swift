//
//  TrackSelectionViewController.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-12-06.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Player

class TrackSelectionViewController: UIViewController {
    
    let backButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action:#selector(goBack), for: .touchUpInside)
        button.setTitle(NSLocalizedString("Back", comment: ""), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        return button
    }()
    
    let audiotTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Audio"
        label.textColor = UIColor.white
        return label
    }()
    
    let subtitlesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Subtitles"
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var audioTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorState.active.background
        return tableView
    }()
    lazy var subtitlesTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorState.active.background
        return tableView
    }()
    
    let cellId = "cell"
    
    var selectedAudio: IndexPath? = nil
    var selectedText: IndexPath? = nil
    var audioViewModels: [TrackSelectionViewModel] = []
    var textViewModels: [TrackSelectionViewModel] = []
    
    override func loadView() {
        super.loadView()
        
        setupLayout()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Track Selection"
        
        audioTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        subtitlesTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        audioTableView.reloadData()
        subtitlesTableView.reloadData()
        
        audioTableView.tableFooterView = UIView()
        subtitlesTableView.tableFooterView = UIView()
        
    }
    
    @objc func goBack() {
        onDismissed()
    }
    
    var onDidSelectAudio: (TrackModel?) -> Void = { _ in }
    var onDidSelectText: (TrackModel?) -> Void = { _ in }
    var onDismissed: () -> Void = { }
    
}

extension TrackSelectionViewController {
    func assign(audio: MediaGroup?) {
        audioViewModels = prepareViewModels(for: audio)
        selectedAudio = (0..<audioViewModels.count).compactMap { index -> IndexPath? in
            let vm = audioViewModels[index]
            if audio?.selectedTrack?.extendedLanguageTag == vm.model?.extendedLanguageTag {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }.last
    }
    
    func assign(text: MediaGroup?) {
        textViewModels = prepareViewModels(for: text)
        selectedText = (0..<textViewModels.count).compactMap { index -> IndexPath? in
            let vm = textViewModels[index]
            if text?.selectedTrack?.extendedLanguageTag == vm.model?.extendedLanguageTag {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }.last
    }
    
    private func prepareViewModels(for mediaGroup: MediaGroup?) -> [TrackSelectionViewModel] {
        guard let mediaGroup = mediaGroup else { return [] }
        var vms = mediaGroup.tracks.map{ TrackSelectionViewModel(model: $0) }
        
        if mediaGroup.allowsEmptySelection {
            let off = TrackSelectionViewModel(model: nil)
            vms.append(off)
        }
        return vms
    }
}


// MARK: - TableView Delegate
extension TrackSelectionViewController: UITableViewDelegate {
    fileprivate func viewModels(for tableView: UITableView) -> [TrackSelectionViewModel] {
        if tableView == audioTableView {
            return audioViewModels
        }
        else if tableView == subtitlesTableView {
            return textViewModels
        }
        return []
    }
    fileprivate func selectedIndexPath(for tableView: UITableView) -> IndexPath? {
        if tableView == audioTableView {
            return selectedAudio
        }
        else if tableView == subtitlesTableView {
            return selectedText
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let track = viewModels(for: tableView)[indexPath.row]
        
        if tableView == audioTableView {
            cell.accessibilityIdentifier = "Audio-\(indexPath.row)"
        }
        if tableView == subtitlesTableView {
            cell.accessibilityIdentifier = "Text-\(indexPath.row)"
        }
        
        cell.backgroundColor = ColorState.active.accentedBackground
        cell.textLabel?.textColor = ColorState.active.text
        cell.textLabel?.text = track.displayName
        cell.accessoryType = selectedIndexPath(for: tableView) == indexPath ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selected = selectedIndexPath(for: tableView), indexPath != selected {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            if let currentlySelected = selectedIndexPath(for: tableView) {
                tableView.cellForRow(at: currentlySelected)?.accessoryType = .none
            }
            
            
            if tableView == audioTableView {
                selectedAudio = indexPath
                onDidSelectAudio(viewModels(for: tableView)[indexPath.row].model)
            }
            else if tableView == subtitlesTableView {
                selectedText = indexPath
                onDidSelectText(viewModels(for: tableView)[indexPath.row].model)
            }
        }
    }
}


// MARK: - TableView Datasource
extension TrackSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels(for: tableView).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
    }
}

// MARK: - Layout
extension TrackSelectionViewController {
    fileprivate func setupLayout() {
        view.addSubview(backButton)
        
        let titleHolderView = UIStackView(arrangedSubviews: [audiotTitleLabel, subtitlesTitleLabel])
        titleHolderView.distribution = .fillEqually
        titleHolderView.axis = .horizontal
        titleHolderView.alignment = .center
        view.addSubview(titleHolderView)
        
        let tablesHolderView = UIStackView(arrangedSubviews: [audioTableView, subtitlesTableView])
        tablesHolderView.distribution = .equalSpacing
        view.addSubview(tablesHolderView)
        
        backButton.anchor(top: view.topAnchor, bottom: nil, leading: nil, trailing: view.trailingAnchor, padding: .init(top: 50, left: 0, bottom: 0, right: 0), size: .init(width: 50, height: 20))
        
        titleHolderView.anchor(top: backButton.bottomAnchor, bottom: tablesHolderView.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        tablesHolderView.anchor(top: nil, bottom: view.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        audioTableView.widthAnchor.constraint(equalTo: tablesHolderView.widthAnchor, multiplier: 0.5).isActive = true
        subtitlesTableView.widthAnchor.constraint(equalTo: tablesHolderView.widthAnchor, multiplier: 0.5).isActive = true
    }
}
