//
//  ChatRoomTableViewCell.swift
//  ios-line
//
//  Created by DAEYOUNG JUNG on 2021/02/23.
//

import UIKit
import Firebase
import FirebaseAuth
import Nuke

class ChatRoomTableViewCell: UITableViewCell {
    
    var message: Message? {
        didSet {
            /*
            if let message = message {
                partnerMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 10
                messageTextViewWidthConstraint.constant = width
                partnerDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
                
            }
            */
        }
    }
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var partnerMessageTextView: UITextView!
    @IBOutlet weak var myMessageTextView: UITextView!
    @IBOutlet weak var partnerDateLabel: UILabel!
    @IBOutlet weak var myDateLabel: UILabel!
    @IBOutlet weak var messageTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var myMessageTextViewWidthConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        userImageView.layer.cornerRadius = 30
        partnerMessageTextView.layer.cornerRadius = 15
        myMessageTextView.layer.cornerRadius = 15
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkWhichUserMessage()
    }
    
    private func checkWhichUserMessage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if uid == message?.uid {
            partnerMessageTextView.isHidden = true
            partnerDateLabel.isHidden = true
            userImageView.isHidden = true
            
            myMessageTextView.isHidden = false
            myDateLabel.isHidden = false
            
            if let message = message {
                myMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 10
                myMessageTextViewWidthConstraint.constant = width
                myDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
                
            }
        } else {
            partnerMessageTextView.isHidden = false
            partnerDateLabel.isHidden = false
            userImageView.isHidden = false
            if let urlString = message?.partnerUser?.profileImageUrl, let url = URL(string: urlString) {
                Nuke.loadImage(with: url, into: userImageView)
            }
            
            myMessageTextView.isHidden = true
            myDateLabel.isHidden = true
            
            
            if let message = message {
                partnerMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 10
                messageTextViewWidthConstraint.constant = width
                partnerDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
                
            }
        }
    }
    
    private func estimateFrameForTextView(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)], context: nil)
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
}
