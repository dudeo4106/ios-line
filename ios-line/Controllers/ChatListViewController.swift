//
//  ChatListViewController.swift
//  ios-line
//
//  Created by DAEYOUNG JUNG on 2021/02/23.
//

import UIKit
import Nuke
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatListViewController: UIViewController {
    
    private let cellId = "cellId"
    private var chatrooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?
    
    private var user: User? {
        didSet {
            navigationItem.title = "Chat List"
        }
    }
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        confirmLoggedInUser()
        fetchChatroomsInfoFromFireStore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchLoginUserInfo()
    }
    
    func fetchChatroomsInfoFromFireStore() {
        chatRoomListener?.remove()
        chatrooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms")
            .addSnapshotListener { (snapshots, err) in
                
                if let err = err {
                    print("Error - Load to chatRoom information \(err)")
                    return
                }
                
                snapshots?.documentChanges.forEach({ (documentChange) in
                    switch documentChange.type {
                    case .added:
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    case .modified, .removed:
                        print("Nothing todo")
                    }
                })
                
            }
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        let dic = documentChange.document.data()
        let chatroom = ChatRoom(dic: dic)
        chatroom.documentId = documentChange.document.documentID
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isContail = chatroom.members.contains(uid)
        
        if !isContail { return }
        
        // private
        if (chatroom.members.count == 2) {
            chatroom.members.forEach { (memberUid) in
                if memberUid != uid {
                    Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                        if let err = err {
                            print ("Error - Load user Information \(err)")
                            return
                        }
                        
                        guard let dic = userSnapshot?.data() else { return }
                        let user = User(dic: dic)
                        user.uid = documentChange.document.documentID
                        chatroom.partnerUser = user
                        chatroom.isGroup = false
                        
                        guard let chatroomId = chatroom.documentId else { return }
                        let latestMessageId = chatroom.latestMessageId
                        
                        if latestMessageId == "" {
                            self.chatrooms.append(chatroom)
                            self.chatListTableView.reloadData()
                            return
                        }
                        
                        Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err) in
                            
                            if let err = err {
                                print ("Error - Load latest Information \(err)")
                                return
                            }
                            
                            guard let dic = messageSnapshot?.data() else { return }
                            let message = Message(dic: dic)
                            chatroom.latestMessage = message
                            
                            self.chatrooms.append(chatroom)
                            self.chatListTableView.reloadData()
                        }
                        
                    }
                }
            }
        }
        // group
        else {
            for memberUid in chatroom.members {
                
                if memberUid != uid {
                    Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                        if let err = err {
                            print ("Error - Load user Information \(err)")
                            return
                        }
                        
                        guard let dic = userSnapshot?.data() else { return }
                        let user = User(dic: dic)
                        user.uid = documentChange.document.documentID
                        chatroom.partnerUser = user
                        chatroom.isGroup = true
                        
                        guard let chatroomId = chatroom.documentId else { return }
                        let latestMessageId = chatroom.latestMessageId
                        
                        if latestMessageId == "" {
                            self.chatrooms.append(chatroom)
                            self.chatListTableView.reloadData()
                            return
                        }
                        
                        Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err) in
                            
                            if let err = err {
                                print ("Error - Load latest Information \(err)")
                                return
                            }
                            
                            guard let dic = messageSnapshot?.data() else { return }
                            let message = Message(dic: dic)
                            chatroom.latestMessage = message
                            
                            self.chatrooms.append(chatroom)
                            self.chatListTableView.reloadData()
                        }

                    }
                    break
                    
                }
                
            }
        }
    }
    
    private func setupViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let rightBarButton = UIBarButtonItem(title: "New chat", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        let logoutBarButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(tappedLogoutBarButton))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    @objc private func tappedLogoutBarButton() {
        do {
            try Auth.auth().signOut()
            pushLoginViewController()
        } catch {
            print ("error - fail to logout \(error)")
        }
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil {
            pushLoginViewController()
        }
        
    }
    
    private func pushLoginViewController() {
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let signUpViewController = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func tappedNavRightBarButton(){
        let storyboard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewController = storyboard.instantiateViewController(withIdentifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewController)
        self.present(nav, animated: true, completion: nil)
    }
    
    private func fetchLoginUserInfo() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err {
                print("fail get user info \(err)")
                return
            }
            
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            
            let user = User(dic: dic)
            self.user = user
        }
        
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatrooms[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatroom = chatrooms[indexPath.row]
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
}

class ChatListTableViewCell: UITableViewCell {
    var chatroom: ChatRoom? {
        didSet {
            if let chatroom = chatroom {
                // private
                if (!chatroom.isGroup) {
                    partnerLabel.text = chatroom.partnerUser?.username
                    
                    guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else { return }
                    Nuke.loadImage(with: url, into: userImageView)
                    
                    dateLabel.text = dateFormatterForDateLabel(date: chatroom.latestMessage?.createdAt.dateValue() ?? Date())
                    lateMessageLabel.text = chatroom.latestMessage?.message
                }
                // group
                else {
                    guard let url = URL(string: "https://firebasestorage.googleapis.com/v0/b/ios-line.appspot.com/o/profile_image%2Ficonfinder_Picture11_3289565.png?alt=media&token=e5793e03-1aed-46a7-a508-6d8c32c6d071") else { return }
                    Nuke.loadImage(with: url as ImageRequestConvertible, into: userImageView)
                    dateLabel.text = dateFormatterForDateLabel(date: chatroom.latestMessage?.createdAt.dateValue() ?? Date())
                    lateMessageLabel.text = chatroom.latestMessage?.message
                    partnerLabel.text = "group"
                }
            }
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var lateMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 30
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
}
