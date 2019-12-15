//
//  GameScene.swift
//  FlappyBird
//
//  Created by 伊藤嵩 on 2019/12/14.
//  Copyright © 2019 Shu Ito. All rights reserved.
//SKSceneクラスを継承

import SpriteKit

class GameScene: SKScene {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    //ゲーム画面（＝SKSceneクラスを継承したクラス）が表示されるときに呼ばれるメソッドがdidMove(to:)メソッド
    //このメソッドで画面を構築する処理を書いたり、ゲームの初期設定を行う
    override func didMove(to view: SKView) {
        //背景色を設定
        //backgroundColorはUIColorクラス
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        //addChild(_:)メソッドでscrollNodeを画面に表示
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
    }
    
    func setupGround() {
        //地面の画像を読み込む
        //SKTextureクラス　表示する画像をSKTextureで扱う、画像のファイル名を指定して作成
        let groundTexture = SKTexture(imageNamed: "ground")
        //SKTextureクラスのfilteringModeプロパティに.nearestと設定
        //.nearrest : 画像が多少荒くなってでも処理速度を高める設定
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        //moveBy:5秒間かけて画像一枚分を左方向にスクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
        
        // テクスチャを指定してスプライトを作成
        let groundSprite = SKSpriteNode(texture: groundTexture)
        //スプライトの表示する位置を指定
        //positionで指定するのはNodeの中心位置
        groundSprite.position = CGPoint (
            x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
            y: groundTexture.size().height / 2
        )
        
        //スプライトにアクションを設定する
        sprite.run(repeatScrollGround)
        
        //スプライトを追加する
        scrollNode.addChild(sprite)
        
        //シーンにスプライトを追加する
        //addChild(_:)メソッドでgroundSpriteを画面に表示
        //addChild(groundSprite)
        }
        
    }
    
    func setupCloud(){
        //雲の画像を読み込み
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        //壁の画像を読み込む
        //当たり判定をする場合、テクスチャは.linerを設定
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        //removeFromParent()メソッドで自身を取り除き表示されないようにする
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        //sequence(_:)メソッドで画面外まで移動するアクションと自身を取り除くアクションを続けて行うアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        
        
        //===========================================================================
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が壁を通り抜ける隙間の長さ(slit_length)
        // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        //隙間位置をランダムに上下させる際の振れ幅(random_y_range)
        // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁のY軸下限位置(under_wall_lowest_y)を計算
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //===========================================================================
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            wall.addChild(upper)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //===========================================================================
        //次の壁作成までの時間待ちのアクションを生成し、「壁を生成→時間待ち」を永遠に繰り返すアクションを生成
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)

    }

}
