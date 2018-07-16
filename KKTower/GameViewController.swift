//
//  GameViewController.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import UIKit
import SpriteKit

let TargetScore = 50

extension Int {
	func format(_ f: String) -> String {
		return NSString(format: "%\(f)d" as NSString, self) as String
	}
}

class GameViewController: UIViewController {
	var scene: GameScene!
	var board: Board!
	
	var remainMatches: Array<Set<Ball>> = []
	var score = 0
	var timer: Timer?
	var startDate: Date?
	
	@IBOutlet var skView: SKView!
	@IBOutlet var timeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

		skView.showsFPS = true
		skView.showsNodeCount = true
		skView.isMultipleTouchEnabled = false
		
		skView.presentScene(scene)
		beginGame()
    }

	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .portrait
	}
	
	func resetGame() {
		score = 0
		timeLabel?.text = "00:00"
		
		board = Board()
		scene = GameScene(size: self.view.frame.size)
		scene.scaleMode = .aspectFill
		scene.board = board
		scene.swapHandler = handleSwap
		scene.didEndMovingHandler = handleDidEndMoving
		
		let newBalls = board.shuffle()
		scene.addNodesForBalls(newBalls)
	}
	
	func beginGame() {
		resetGame()
		skView.presentScene(scene, transition: SKTransition.flipVertical(withDuration: 0.5))
		
		timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(GameViewController.updateTime), userInfo: nil, repeats: true)
		startDate = Date()
	}
	
	@objc func updateTime() {
		let interval = -startDate!.timeIntervalSinceNow
		let minute: Int = Int(interval) / 60
		let second: Int = Int(interval) % 60
		let f = "02"
		timeLabel?.text = "\(minute.format(f)):\(second.format(f))"
	}
	
	func handleSwap(_ ball1: Ball, ball2: Ball) {
		board.performSwap(ball1, ball2: ball2)
		scene.animateSwap(ball1, ball2:ball2)
	}
	
	func handleDidEndMoving() {
		let matches = board.removeMatches()
		
		if matches.count == 0 {
			if score >= TargetScore {
				beginGame()
			}
			view.isUserInteractionEnabled = true
			return
		}
		
		remainMatches = matches
		view.isUserInteractionEnabled = false
		
		animateRemainMatches()
	}
	
	func animateRemainMatches() {
		if remainMatches.count == 0 {
			let (newFalls, falls) = self.board.fillHoles()
			
			self.scene.addNodesForFalls(newFalls)
			self.scene.animateFallingBalls(falls) {
				self.handleDidEndMoving()
			}
			return
		}
		let match = remainMatches.removeLast()
		score += match.count()
		scene.animateMatchRemoval(match) {
			self.scene.animateScore(self.score, animate: true, completion: self.animateRemainMatches)
		}
	}
}
