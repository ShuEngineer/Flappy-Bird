//
//  ViewController.swift
//  FlappyBird
//
//  Created by 伊藤嵩 on 2019/12/14.
//  Copyright © 2019 Shu Ito. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //SKViewに型を変換する
        //skViewをSKView型にキャスト
        //as! にすることでアンラップ
        let skView = self.view as! SKView
        
        //FPSを表示する
        //showsFPSプロパティ:画面が1秒間に何回更新されているかを示すFPSを画面の右下に表示させるもの
        skView.showsFPS = true
        
        //ノードの数を表示する
        //showsNodeCountプロパティ:ノードが幾つ表示されているかを画面の右下に表示させるもの
        skView.showsNodeCount = true
        
        //ビューと同じサイズでシーンを作成する
        let scene = GameScene(size: skView.frame.size)
        
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }

    // 画面上部のステータスバー（時間などが表示されている部分）を消す
    //ViewController.swiftでprefersStatusBarHiddenプロパティをオーバーライドし、常にtrue(非表示)を返すように設定
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

