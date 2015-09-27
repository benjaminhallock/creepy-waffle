//
//  MessagesView.swift
//  Snap Ben
//
//  Created by benjaminhallock@gmail.com on 9/15/15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

import Foundation
import UIKit

class Inbox: UIViewController
{
    var didViewJustLoad = false

    var longPress = UILongPressGestureRecognizer()

    override func viewDidLoad ()
    {
        super.viewDidLoad()

        IQKeyboardManager.sharedManager().enableAutoToolbar = false

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Bordered, target: self, action: "didPressEdit")
        
//        self.viewEmpty.hidden = true;
        self.didViewJustLoad = true;
        self.navigationItem.title = "SnapBen";

        longPress = UILongPressGestureRecognizer(target: self, action: "longPress")

        self.view.addGestureRecognizer(longPress)
    }


    @IBAction func didSelectCompose()
    {
    let chat = CreateChatroomView()
    chat.isTherePicturesToSend = false;
    self.hidesBottomBarWhenPushed = true;
    self.navigationController?.pushViewController(chat, animated: true)
    self.hidesBottomBarWhenPushed = false;
    }


}