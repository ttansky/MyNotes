//
//  ViewController.swift
//  MyNotes
//
//  Created by Тарас on 5/22/19.
//  Copyright © 2019 Taras. All rights reserved.
//

import UIKit
import RealmSwift

class NotesListViewController: UITableViewController, CreateNewNoteDelegate {
    
    let realm = try! Realm()
    let defaults = UserDefaults.standard
    let searchController = UISearchController(searchResultsController: nil)
    var notes : Results<Note>?
    var editingNoteRow : Int?
    var filteredNotes = [Note]()
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        tableView.register(UINib(nibName: "NoteCustomCell", bundle: nil), forCellReuseIdentifier: "NoteCustomCell")
        loadNotes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    
    //MARK: - TableView Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredNotes.count
        }
        if notes?.count == 0 {
            sortButton.isEnabled = false
            tableView.setEmptyView(title: "У вас пока нет заметок :(", message: "Чтобы добавить заметку, нажмите на кнопку в верхнем правом углу")
        }
        else {
            sortButton.isEnabled = true
            tableView.restore()
        }
        
        return notes?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCustomCell", for: indexPath) as! NoteCustomCell
        
        func cellDateSetup(date: Date?) {
            let dateFormatterForDateLabel = DateFormatter()
            let dateFormatterForTimeLabel = DateFormatter()
            dateFormatterForDateLabel.dateFormat = "dd.MM.yyyy"
            dateFormatterForTimeLabel.dateFormat = "HH:mm"
            if let noteDate = date {
                let dateString = dateFormatterForDateLabel.string(from: noteDate)
                let timeString = dateFormatterForTimeLabel.string(from: noteDate)
                cell.dateLabel.text = dateString
                cell.timeLabel.text = timeString
            }
        }
        
        if isFiltering() {
            cell.noteTextLabel.text = filteredNotes[indexPath.row].noteText.maxLength(length: 100)
            cellDateSetup(date: filteredNotes[indexPath.row].noteDate)
        } else {
            if let note = notes?[indexPath.row] {
            cell.noteTextLabel.text = note.noteText.maxLength(length: 100)
            cellDateSetup(date: note.noteDate)
            }
        }
        
        return cell
    }
    
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! DetailsViewController
        destinationVC.delegate = self
        if segue.identifier == "goToDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                if isFiltering() {
                    destinationVC.selectedNote = filteredNotes[indexPath.row]
                } else {
                    destinationVC.selectedNote = notes?[indexPath.row]
                }
            }
            if let noteToEdit = editingNoteRow {
                if isFiltering() {
                    if filteredNotes[noteToEdit].canEdit {
                        destinationVC.selectedNote = filteredNotes[noteToEdit]
                    }
                } else {
                    if let editable = notes?[noteToEdit].canEdit {
                        if editable {
                            destinationVC.selectedNote = notes?[noteToEdit]
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK: - SwipeActions
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = deleteAction(at: indexPath)
        let edit = editAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    func deleteAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            
            if self.isFiltering() {
                let note = self.filteredNotes[indexPath.row]
                do {
                    try self.realm.write {
                        self.realm.delete(note)
                        self.filteredNotes.remove(at: indexPath.row)
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Error deleting note, \(error)")
                }
            } else {
                if let note = self.notes?[indexPath.row] {
                    do {
                        try self.realm.write {
                            self.realm.delete(note)
                            self.tableView.reloadData()
                        }
                    } catch {
                        print("Error deleting note, \(error)")
                    }
                }
            }
        }
        action.backgroundColor = .red
        return action
    }
    
    func editAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
            if self.isFiltering() {
                let noteToEdit = self.filteredNotes[indexPath.row]
                do {
                    try self.realm.write {
                        noteToEdit.canEdit = true
                    }
                } catch {
                    print("Error deleting note, \(error)")
                }
            } else {
                if let note = self.notes?[indexPath.row] {
                    do {
                        try self.realm.write {
                            note.canEdit = true
                        }
                    } catch {
                        print("Error editing note, \(error)")
                    }
                }
            }
            self.editingNoteRow = indexPath.row
            self.performSegue(withIdentifier: "goToDetails", sender: self)
            
        }
        action.backgroundColor = .darkGray
        return action
    }
    
    //MARK: - Data Manipulation Methods
    
    func save(note: Note) {
        do {
            try realm.write {
                realm.add(note)
            }
        } catch {
            print("Error saving note \(error)")
        }
        tableView.reloadData()
        
    }
    //loading in saved order
    func loadNotes() {
        switch defaults.string(forKey: "Sorting") {
        case "fromNew":
            notes = realm.objects(Note.self).sorted(byKeyPath: "noteDate", ascending: false)
        case "fromOld":
            notes = realm.objects(Note.self).sorted(byKeyPath: "noteDate", ascending: true)
        case "fromAtoZ":
            notes = realm.objects(Note.self).sorted(byKeyPath: "noteText", ascending: true)
        case "fromZtoA":
            notes = realm.objects(Note.self).sorted(byKeyPath: "noteText", ascending: false)
        default:
            notes = realm.objects(Note.self)
        }
        tableView.reloadData()
    }
    
    //MARK: - Add new note
    
    @IBAction func addNoteButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToNew", sender: self)
    }
    
    func addNewNote(note: String) {
        let newNote = Note()
        newNote.noteText = note
        newNote.noteDate = Date()
        self.save(note: newNote)
        tableView.reloadData()
    }
    
    //MARK: - Searchcontroller setup
    
    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по заметкам"
        navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        if let allNotes = notes {
            filteredNotes = allNotes.filter({( note : Note) -> Bool in
                return note.noteText.lowercased().contains(searchText.lowercased())
            })
        }
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    //MARK: - Sorting setup
    
    @IBAction func sortButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Сортировка заметок", message: "Вы можете отсортировать заметки по дате или имени", preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "По дате", style: .default) { (action) in
            let dateSortAlert = UIAlertController(title: "Сортировка по дате", message: nil, preferredStyle: .actionSheet)
            let fromNew = UIAlertAction(title: "От новых к старым", style: .default, handler: { (action) in
                do {
                    try self.realm.write {
                        self.notes = self.realm.objects(Note.self).sorted(byKeyPath: "noteDate", ascending: false)
                        self.defaults.set("fromNew", forKey: "Sorting")
                    }
                } catch {
                    print("Error sorting notes, \(error)")
                }
                self.tableView.reloadData()
            })
            let fromOld = UIAlertAction(title: "От старых к новым", style: .default, handler: { (action) in
                do {
                    try self.realm.write {
                        self.notes = self.realm.objects(Note.self).sorted(byKeyPath: "noteDate", ascending: true)
                        self.defaults.set("fromOld", forKey: "Sorting")
                    }
                } catch {
                    print("Error sorting notes, \(error)")
                }
                self.tableView.reloadData()
            })
            dateSortAlert.addAction(fromNew)
            dateSortAlert.addAction(fromOld)
            self.present(dateSortAlert, animated: true) {
                //closing actionsheet when user touch outside
                self.tapRecognizer(alert: dateSortAlert)
            }
        }
        
        let action2 = UIAlertAction(title: "По имени", style: .default) { (action) in
            let nameSortAlert = UIAlertController(title: "Сортировка по имени", message: nil, preferredStyle: .actionSheet)
            let fromAtoZ = UIAlertAction(title: "А-Я", style: .default, handler: { (action) in
                do {
                    try self.realm.write {
                        self.notes = self.realm.objects(Note.self).sorted(byKeyPath: "noteText", ascending: true)
                        self.defaults.set("fromAtoZ", forKey: "Sorting")
                    }
                } catch {
                    print("Error sorting notes, \(error)")
                }
                self.tableView.reloadData()
            })
            let fromZtoA = UIAlertAction(title: "Я-А", style: .default, handler: { (action) in
                do {
                    try self.realm.write {
                        self.notes = self.realm.objects(Note.self).sorted(byKeyPath: "noteText", ascending: false)
                        self.defaults.set("fromZtoA", forKey: "Sorting")
                    }
                } catch {
                    print("Error sorting notes, \(error)")
                }
                self.tableView.reloadData()
            })
            nameSortAlert.addAction(fromAtoZ)
            nameSortAlert.addAction(fromZtoA)
            self.present(nameSortAlert, animated: true) {
                self.tapRecognizer(alert: nameSortAlert)
            }
            
        }
        alert.addAction(action1)
        alert.addAction(action2)
        present(alert, animated: true) {
            self.tapRecognizer(alert: alert)
        }
    }
    
    func tapRecognizer(alert: UIAlertController) {
        alert.view.superview?.subviews.first?.isUserInteractionEnabled = true
        alert.view.superview?.subviews.first?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.actionSheetBackgroundTapped)))
    }
    
    @objc func actionSheetBackgroundTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - Extensions

extension String {
    func maxLength(length: Int) -> String {
        var str = self
        let nsString = str as NSString
        if nsString.length >= length {
            str = nsString.substring(with:
                NSRange(
                    location: 0,
                    length: nsString.length > length ? length : nsString.length)
            )
        }
        return  str
    }
}

extension NotesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            filterContentForSearchText(text)
        }
    }

}

extension UITableView {
    func setEmptyView(title: String, message: String) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
