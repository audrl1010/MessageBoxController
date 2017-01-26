//
//  MessageBoxController.swift
//  MessageBoxControllerDemo
//
//  Created by gru on 2017. 1. 26..
//  Copyright © 2017년 com.myungGiSon. All rights reserved.
//

import UIKit

protocol MessageBoxControllable
{
    /** 설정 */
    var configuration: MessageBoxConfiguration { get set }
}

extension MessageBoxController
{
    static func show(message: String? = nil, animated: Bool = true)
    {
        if let unWrappingMessage = message
        {
            shared.configuration.message = unWrappingMessage
            shared.configuration.isAnimated = animated
        }
        shared.execute()
    }
}


class MessageBoxController: MessageBoxControllable
{
    /** Properties */
    var uppermostDisplayedMessageBoxView: MessageBoxView?
    
    let messageBoxSerialQueue: DispatchQueue = DispatchQueue(label: "com.messageBox.serialQueue")
    
    let dispatchGroup: DispatchGroup = DispatchGroup()
    
    var configuration = MessageBoxConfiguration.shared
    
    static var shared: MessageBoxController {
        struct Static {
            static let instance: MessageBoxController = MessageBoxController()
        }
        return Static.instance
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    init()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: .UIDeviceOrientationDidChange,
                                               object: nil)
    }
    
    @objc func orientationChanged()
    {
        guard let uppermostDisplayedMessageBoxViewRect = uppermostDisplayedMessageBoxView?.frame else {
            return
        }
        
        let screenWidth = UIScreen.main.bounds.size.width
        uppermostDisplayedMessageBoxView?.frame = CGRect(x: uppermostDisplayedMessageBoxViewRect.origin.x,
                                                         y: uppermostDisplayedMessageBoxViewRect.origin.y,
                                                         width: screenWidth,
                                                         height: uppermostDisplayedMessageBoxViewRect.height)
        
        uppermostDisplayedMessageBoxView?.setNeedsDisplay()
    }
    
    /** */
    fileprivate func execute()
    {
        // 1.
        dispatchGroup.enter()
        
        // 2.
        messageBoxSerialQueue.async {
            DispatchQueue.main.async { [unowned self] in
                
                // 3.
                UIApplication.shared.isStatusBarHidden = true
                
                // 4.
                let messageBoxViewCreated = self.createMessageBoxView()
                
                // 5. 현재 보여지고 있는 메시지 박스 뷰를 cache해놓는다.
                //    방향 전환이 있을 경우 캐쉬해놓은 메시지 박스 뷰의 rect값을 변경하기 위해서 이다.
                self.uppermostDisplayedMessageBoxView = messageBoxViewCreated
                
                // 6.
                UIApplication.shared.keyWindow?.addSubview(messageBoxViewCreated)
                
                // 7.
                self.animate(messageBoxView: messageBoxViewCreated) { [unowned self] in
                    
                    DispatchQueue.main.async { [unowned messageBoxViewCreated] in
                        messageBoxViewCreated.removeFromSuperview()
                    }
                    
                    self.dispatchGroup.leave()
                }
            }
        }
        
        // 7.
        dispatchGroup.notify(queue: DispatchQueue.main) {
            UIApplication.shared.isStatusBarHidden = false
        }
    }
    
    /** */
    fileprivate func createMessageBoxView() -> MessageBoxView
    {
        let screenSize = UIScreen.main.bounds
        let messageBoxView = MessageBoxView(frame: CGRect(x: 0,
                                                          y: -configuration.messageBoxViewHeight,
                                                          width: screenSize.width,
                                                          height: configuration.messageBoxViewHeight))
        messageBoxView.backgroundColor = configuration.backgroundColor
        messageBoxView.messageLabel.text = configuration.message
        messageBoxView.messageLabel.font = configuration.messageFont
        messageBoxView.messageLabel.textColor = .white
        return messageBoxView
    }
    
    /** */
    fileprivate func animate(messageBoxView: MessageBoxView, finished: @escaping () -> Void)
    {
        if configuration.isAnimated {
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           options: [.curveEaseInOut],
                           animations: { [unowned self, messageBoxView] in
                            messageBoxView.center.y += self.configuration.messageBoxViewHeight
                }, completion: nil)
            UIView.animate(withDuration: 0.5, delay: 4.0,
                           options: [.curveEaseInOut],
                           animations: { [unowned self, messageBoxView] in
                            messageBoxView.center.y -= self.configuration.messageBoxViewHeight
                }, completion: { (_) in
                    finished()
            })
        } else {
            messageBoxView.center.y += self.configuration.messageBoxViewHeight
            
            delay(time: 1.0) { [unowned messageBoxView] in
                messageBoxView.center.y -= self.configuration.messageBoxViewHeight
                finished()
            }
        }
    }
}

// MARK: MessageBoxConfiguration
class MessageBoxConfiguration
{
    var messageBoxViewHeight: CGFloat = 20
    var message: String = "message"
    var backgroundColor: UIColor = .red
    var messageFont: UIFont = UIFont.boldSystemFont(ofSize: 14)
    var messageColor: UIColor = .white
    var isAnimated: Bool = false
    
    static var shared: MessageBoxConfiguration {
        struct Static {
            static let instance: MessageBoxConfiguration = MessageBoxConfiguration()
        }
        return Static.instance
    }
}

// MARK: MessageBoxView
class MessageBoxView: UIView
{
    var messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }
    
    func setupViews()
    {
        backgroundColor = UIColor.red
        addSubview(messageLabel)
    }
    
    func setupConstraints()
    {
        messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}

func delay(time: Double, closure: @escaping () -> ())
{
    DispatchQueue.main.asyncAfter(deadline: .now() + time) {
        closure()
    }
}

