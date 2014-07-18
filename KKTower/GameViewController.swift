//
//  GameViewController.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
	var scene: GameScene!
	var board: Board!
	
	var remainMatches: Array<Set<Ball>> = []
	var score = 0

    override func viewDidLoad() {
        super.viewDidLoad()

		let skView = view as SKView
		skView.showsFPS = true
		skView.showsNodeCount = true
		skView.multipleTouchEnabled = false
		
		board = Board()
		scene = GameScene(size: self.view.frame.size)
		scene.scaleMode = .AspectFill
		scene.board = board
		scene.swapHandler = handleSwap
		scene.didEndMovingHandler = handleDidEndMoving
		
		skView.presentScene(scene)
		beginGame()
    }

	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Portrait.toRaw())
    }
	
	func beginGame() {
		let newBalls = board.shuffle()
		
		scene.addNodesForBalls(newBalls)
	}
	
	func handleSwap(ball1: Ball, ball2: Ball) {
		board.performSwap(ball1, ball2: ball2)
		scene.animateSwap(ball1, ball2:ball2)
	}
	
	func handleDidEndMoving() {
		let matches = board.removeMatches()
		
		if matches.count == 0 {
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
		scene.animateScore(score, animate: true) {}
		scene.animateMatchRemoval(match, animateRemainMatches)
	}
}
