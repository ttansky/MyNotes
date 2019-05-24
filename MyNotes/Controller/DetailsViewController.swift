//
//  DetailsViewController.swift
//  MyNotes
//
//  Created by Тарас on 5/22/19.
//  Copyright © 2019 Taras. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

protocol CreateNewNoteDelegate {
    func addNewNote(note: String)
}

class DetailsViewController: UIViewController {

    @IBOutlet weak var fullNoteTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate : CreateNewNoteDelegate?
    var selectedNote : Note?
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setDefaultStyle(.dark)
        loadNote()
        if fullNoteTextView.text.isEmpty {
            self.fullNoteTextView.becomeFirstResponder()
        } else {
            if let note = selectedNote {
                if note.canEdit {
                    saveButton.title = "Редактировать"
                    self.fullNoteTextView.becomeFirstResponder()
                } else {
                    saveButton.isEnabled = false
                    saveButton.title = ""
                    fullNoteTextView.isEditable = false
                    //add share button
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed(paramSender:))), animated: true)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            if let note = selectedNote {
                do {
                    try realm.write {
                        note.canEdit = false
                    }
                } catch {
                    print("Error saving note, \(error)")
                }
            }
        }
    }
    
    //MARK: - Save button method
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if saveButton.title == "Редактировать" {
            if let note = selectedNote {
                do {
                    try realm.write {
                        if fullNoteTextView.text != "" {
                            note.noteText = fullNoteTextView.text
                            note.noteDate = Date()
                            note.canEdit = false
                            SVProgressHUD.showSuccess(withStatus: "Заметка отредактирована")
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            SVProgressHUD.showError(withStatus: "Заметка не может быть пустой")
                        }
                    }
                } catch {
                    print("Error saving note, \(error)")
                }
            }
        } else {
            if let enteredText = self.fullNoteTextView.text {
                if enteredText != "" {
                    delegate?.addNewNote(note: enteredText)
                    SVProgressHUD.showSuccess(withStatus: "Заметка добавлена")
                    self.navigationController?.popViewController(animated: true)
                } else {
                    SVProgressHUD.showError(withStatus: "Заметка не может быть пустой")
                }
            }
        }
    }
    
    //MARK: - Share button method
    
    @objc func shareButtonPressed(paramSender: Any) {
        let text = self.fullNoteTextView.text
        let textShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textShare as [Any] , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    //MARK: - Model manipulation method
    
    func loadNote() {
        fullNoteTextView.text = selectedNote?.noteText
    }
    
 
}
