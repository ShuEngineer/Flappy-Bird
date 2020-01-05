//
//  GameScene.swift
//  FlappyBird
//
//  Created by 伊藤嵩 on 2019/12/14.
//  Copyright © 2019 Shu Ito. All rights reserved.
//SKSceneクラスを継承

import SpriteKit

                        //↓GameSceneクラスにSKPhysicsContactDelegateプロトコルを実装
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var masterChromeNode:SKNode!
    
    
    // 衝突判定カテゴリー,衝突判定に使うカテゴリーの値,カテゴリーを使ってどのスプライト同士が衝突したかを判断
    //壁をくぐったことを判定するために上側の壁と下側の壁の間に見えない物体を配置して、
    //これに衝突したときにくぐったと判断してスコアをカウントアップ
    let birdCategory: UInt32 = 1 << 0       // 0...00001 鳥
    let groundCategory: UInt32 = 1 << 1     // 0...00010 地面
    let wallCategory: UInt32 = 1 << 2       // 0...00100 壁
    let scoreCategory: UInt32 = 1 << 3      // 0...01000 スコア用の物体
    let chromeCategory: UInt32 = 1 << 4     // 0...10000 chrome用の物体

    // スコア用
    var score = 0
    
    //chromeスコア用
    var chromeScore = 0
    
    //画面上部にスコアを表示できるように、SKLabelNodeクラスを２つ定義
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var chromeScoreLabelNode:SKLabelNode!
    //UserDefaultsクラスのUserDefaults.standardプロパティでUserDefaultsを取得
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //chrome取得時のsound
    let chromeSound = SKAction.playSoundFileNamed("CoinSound.mp3", waitForCompletion: false)
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    //ゲーム画面（＝SKSceneクラスを継承したクラス）が表示されるときに呼ばれるメソッドがdidMove(to:)メソッド
    //このメソッドで画面を構築する処理を書いたり、ゲームの初期設定を行う
    override func didMove(to view: SKView) {
        //重力の設定はSKPhysicsWorldクラスのgravityプロパティで設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        //SKPhysicsWorldクラスのdelegateプロパティに設定
        physicsWorld.contactDelegate = self
        
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
        
        //chrome用のノード
        masterChromeNode = SKNode()
        scrollNode.addChild(masterChromeNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupChrome()
        
        setupScoreLabel()
    }
    
    //===========================================================================
    //スコア文字の表示部分の初期化
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        //fontColorプロパティで文字の色を指定
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        //horizontalAlignmentModeプロパティで左詰めかセンタリングか右詰めかを指定
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //chromeスコアの表示
        chromeScoreLabelNode = SKLabelNode()
        chromeScoreLabelNode.fontColor = UIColor.black
        chromeScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        chromeScoreLabelNode.zPosition = 100 // 一番手前に表示する
        chromeScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let chromeScore = userDefaults.integer(forKey: "chrome")
        chromeScoreLabelNode.text = "Chrome Score:\(chromeScore)"
        self.addChild(chromeScoreLabelNode)
    }
    
    //===========================================================================
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
            // テクスチャを指定してスプライトを作成
            let sprite = SKSpriteNode(texture: groundTexture)
            //let groundSprite = SKSpriteNode(texture: groundTexture)
            //スプライトの表示する位置を指定
            //positionで指定するのはNodeの中心位置
            sprite.position = CGPoint (
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
        
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
              sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定する
            //地面なので四角形で物理体を設定
            //SKPhysicsBodyクラスのisDynamicプロパティにfalseを設定することで重力の影響を受けず、衝突時に動かない
            sprite.physicsBody?.isDynamic = false
        
            //スプライトを追加する
            scrollNode.addChild(sprite)
            //シーンにスプライトを追加する
            //addChild(_:)メソッドでgroundSpriteを画面に表示
            //addChild(groundSprite)
        }
        
    }
    
    
    //===========================================================================
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
    
    
    //===========================================================================
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
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //壁にカテゴリー設定し、スコア用の物体を追加
            //categoryBitMaskプロパティで自身のカテゴリー(wallCategory)を設定し、
            //contactTestBitMaskプロパティで衝突することを判定する相手のカテゴリー(birdCategory)を設定
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
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
    
    func setupChrome() {
        //chromeの画像を読み込む
        let chromeTexture = SKTexture(imageNamed: "chrome")
        chromeTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + chromeTexture.size().width * 3)
        //let movingDistance = CGFloat(self.frame.size.width)
        // 画面外まで移動するアクションを作成
        //x軸を4秒かけて移動する
        let moveChrome = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.5)

        // 自身を取り除くアクションを作成
        //removeFromParent()メソッドで自身を取り除き表示されないようにする
        let removeChrome = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアクションを作成
        //sequence(_:)メソッドで画面外まで移動するアクションと自身を取り除くアクションを続けて行うアクションを作成
        let chromeAnimation = SKAction.sequence([moveChrome, removeChrome])

        //print(self.frame.size.width
        //アイテムがスクロールした後に削除する作業をrun
        //chrome.run(chromeAnimation)
    //===========================================================================
        // chromeを生成するアクションを作成
        let createChromeAnimation = SKAction.run({
            // chrome関連のノードを乗せるノードを作成
            let chromeNode = SKNode()
            chromeNode.position = CGPoint(
                x: self.frame.size.width + chromeTexture.size().width * 3, y: 0)
            chromeNode.zPosition = -30 // 雲より手前、地面より奥
            //y軸にランダムな値を設定
            let chromeNode_y = CGFloat.random(in: 200 ..< 400)
            //textureを指定してスプライトを作成する
            let chrome = SKSpriteNode(texture: chromeTexture)
            chrome.position = CGPoint(
                //chromeNode.positionでx軸は設定したため、y軸を設定する
                x: 0,
                //y: chromeNode_y
                y: 400
            )
            //スプライトに衝突判定を設定する
            chrome.physicsBody?.categoryBitMask = self.chromeCategory
            chrome.physicsBody = SKPhysicsBody(texture: chromeTexture, size: chromeTexture.size())
            chrome.physicsBody?.isDynamic = false
            chrome.physicsBody?.categoryBitMask = self.chromeCategory
            chrome.physicsBody?.collisionBitMask = self.birdCategory
            chrome.physicsBody?.contactTestBitMask = self.birdCategory

            chromeNode.addChild(chrome)
            chromeNode.run(chromeAnimation)
        //シーンにchromeを追加する
        self.masterChromeNode.addChild(chromeNode)
    
    })
        //===========================================================================
        //次のchrome作成までの時間待ちのアクションを生成し、「chromeを生成→時間待ち」を
        //永遠に繰り返すアクションを生成
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 6)
        
        // chromeを作成->時間待ち->chromeを作成を無限に繰り返すアクションを作成
        let repeatForeverChromeAnimation = SKAction.repeatForever(SKAction.sequence([createChromeAnimation, waitAnimation]))
        //scrollNodeの配下に直接あるmasterChromeNode??
        //********************1つのSKSpriteNodeには１つのSKActionしか設定できない？？************
        masterChromeNode.run(repeatForeverChromeAnimation)
    }
    
    //===========================================================================
    func setupBird() {
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のTextureを交互に表示するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
    
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x:self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //物理演算を設定
        //鳥のスプライトに半径を指定して円形の物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリービットマスクを設定
        //collisionBitMaskプロパティ:当たった時に跳ね返る動作をする相手を設定
        //contactTestBitMaskプロパティ：接触の検知
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | chromeCategory
        
    
    
        //アニメーションを設定
        bird.run(flap)
    
        //スプライトを追加する
        addChild(bird)
        
    }

    //===========================================================================
    //画面をタップした時に鳥を上方向に動かす処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //ゲーム中の時(scrollNodeのspeedプロパティが0より大きい時)だけ鳥が羽ばたく
        if scrollNode.speed > 0 {
        // 鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        //bird.physicsBody?.velocity = CGVector(dx:0,dy:-3.0)
        // 鳥に縦方向の力を与える
        //dx 横への力　dy 縦への力
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        
         //ゲームオーバー状態(scrollNodeのspeedプロパティが0)で鳥の回転アクションが
        //停止(birdのspeedプロパティが0)になっていたら、restart()メソッドを呼び出してゲームを再開
        }else if bird.speed == 0 {
            restart()
        
        }
        
    }
    
    //===========================================================================
    //SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時はなにもしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した　=> 隙間を通過した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            //ベストスコア更新か判定
            //UserDefaultsはキーと値を指定して保存
            //integer(forKey:)メソッドでキーを指定して取得
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                //ベストスコアが更新されていればset(_:forKey:)メソッドで値とキーを指定して保存
                userDefaults.set(bestScore, forKey: "BEST")
                //即座に保存させるためにsynchronize()メソッドを呼ぶ
                userDefaults.synchronize()
            }
            
        }else if (contact.bodyA.categoryBitMask & chromeCategory) == chromeCategory || (contact.bodyB.categoryBitMask & chromeCategory) == chromeCategory {
            //chromeアイテムに衝突した際にスコアをカウント
            print("ItemScoreUp")
            chromeScore += 1
            chromeScoreLabelNode.text = "ChromeScore:\(chromeScore)"
            //↓chromeアイテムを削除可能　なぜ？
            contact.bodyA.node?.removeFromParent() //contact.bodyA:chrome
            //contact.bodyB.node?.removeFromParent() //contact.bodyB:bird
            
            
        }else{
            //壁か地面と衝突した場合
            print("GameOver")
            //scoreLabelNode.text = "GameOver"
            
            //スクロールを停止させる
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        
        }
        
        
    }
    
    //===========================================================================
    //衝突後に画面をタップしてリスタートさせる処理
    func restart() {
        //スコアを0に戻す
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        //chromeスコアを0に戻す
        chromeScore = 0
        chromeScoreLabelNode.text = "Score:\(chromeScore)"
        //鳥の位置を初期位置に戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        masterChromeNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
        
}
