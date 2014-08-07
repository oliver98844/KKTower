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
	func format(f: String) -> String {
		return NSString(format: "%\(f)d", self)
	}
}

class GameViewController: UIViewController {
	var scene: GameScene!
	var board: Board!
	var skView: SKView!
	
	var remainMatches: Array<Set<Ball>> = []
	var score = 0
	var timer: NSTimer?
	var startDate: NSDate?
	
	@IBOutlet var timeLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

		skView = view as SKView
		skView.showsFPS = true
		skView.showsNodeCount = true
		skView.multipleTouchEnabled = false
		
		skView.presentScene(scene)
		beginGame()
    }

	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Portrait.toRaw())
    }
	
	func resetGame() {
		score = 0
		timeLabel?.text = "00:00"
		
		board = Board()
		scene = GameScene(size: self.view.frame.size)
		scene.scaleMode = .AspectFill
		scene.board = board
		scene.swapHandler = handleSwap
		scene.didEndMovingHandler = handleDidEndMoving
		
		let newBalls = board.shuffle()
		scene.addNodesForBalls(newBalls)
	}
	
	func beginGame() {
		resetGame()
		skView.presentScene(scene, transition: SKTransition.flipVerticalWithDuration(0.5))
		
		timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
		startDate = NSDate()
	}
	
	func updateTime() {
		let interval = -startDate!.timeIntervalSinceNow
		let minute: Int = Int(interval) / 60
		let second: Int = Int(interval) % 60
		let f = "02"
		timeLabel?.text = "\(minute.format(f)):\(second.format(f))"
	}
	
	func handleSwap(ball1: Ball, ball2: Ball) {
		board.performSwap(ball1, ball2: ball2)
		scene.animateSwap(ball1, ball2:ball2)
	}
	
	func handleDidEndMoving() {
		let matches = board.removeMatches()
		
		if matches.count == 0 {
			if score >= TargetScore {
				beginGame()
			}
			view.userInteractionEnabled = true
			return
		}
		
		remainMatches = matches
		view.userInteractionEnabled = false
		
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
			self.scene.animateScore(self.score, animate: true, self.animateRemainMatches)
		}
	}
}
