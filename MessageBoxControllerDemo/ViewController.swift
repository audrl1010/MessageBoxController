//
//  ViewController.swift
//  MessageBoxControllerDemo
//
//  Created by gru on 2017. 1. 26..
//  Copyright © 2017년 com.myungGiSon. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTouchButton()
    {
        MessageBoxController.show(message: "인터넷이 연결되지 않았습니다.", animated: true)
    }
}

