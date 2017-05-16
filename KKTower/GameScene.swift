//
//  GameScene.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import UIKit
import SpriteKit

let TimerHeight: CGFloat = 10.0

class BallNode: SKShapeNode {
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	init(color: BallColor, width: CGFloat) {
		super.init()
		let ovalPath = CGMutablePath()
		ovalPath.addArc(center: CGPoint(x: 0.0, y: 0.0), radius: width / 2, startAngle: 0.0, endAngle: CGFloat(2.0 * .pi), clockwise: false)
		self.path = ovalPath
		self.fillColor = color.color
	}
}

class TimerNode: SKShapeNode {
	let bar = SKShapeNode()
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	init(size: CGSize) {
		super.init()
		self.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height)).cgPath
		self.lineWidth = 0
		
		let border = SKShapeNode()
		border.path = UIBezierPath(rect: CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2)).cgPath
		addChild(border)
		
		bar.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width - 4, height: size.height - 4)).cgPath
		bar.position = CGPoint(x: 2.0, y: 2.0)
		bar.lineWidth = 0
		bar.fillColor = BallColor.green.color
		addChild(bar)
	}
	
	func setPercentage(_ percentage: Float) {
		var percentage = percentage
		percentage = percentage > 1.0 ? 1.0 : percentage
		percentage = percentage < 0.0 ? 0.0 : percentage
		bar.path = UIBezierPath(rect: CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(Float(frame.size.width - 4.0) * percentage), height: CGFloat(frame.size.height - 4.0))).cgPath
		bar.fillColor = percentage > 0.3 ? BallColor.green.color : BallColor.red.color
	}
}

class GameScene: SKScene {
	var board: Board!
	
	let tileWidth: CGFloat
	var ballWidth: CGFloat { get { return tileWidth - 6 } }
	
	let gameLayer = SKNode()
	let ballsLayer = SKNode()
	let tilesLayer = SKNode()
	let particleLayer = SKNode()
	let timerNode: TimerNode
	let scoreNode = SKLabelNode(fontNamed: "GillSans-BoldItalic")
	
	var movingNode: BallNode?
	var movingBall: Ball?
	var moveStartTime: TimeInterval?
	
	var swapHandler: ((Ball, Ball) -> ())?
	var didEndMovingHandler: (() -> ())?
	
	var currentTime: TimeInterval = 0
	
	required init?(coder aDecoder: NSCoder) {
		tileWidth = 0.0
		timerNode = TimerNode(size: CGSize(width: 320.0, height: TimerHeight))
		
		super.init(coder: aDecoder)
	}
	
	override init(size: CGSize) {
		tileWidth = size.width / CGFloat(NumColumns)
		timerNode = TimerNode(size: CGSize(width: size.width, height: TimerHeight))
		timerNode.position = CGPoint(x: 0, y: tileWidth * CGFloat(NumRows))
		
		super.init(size: size)
		
		self.backgroundColor = UIColor.brown
		
		addChild(gameLayer)
		
		gameLayer.addChild(tilesLayer)
		gameLayer.addChild(ballsLayer)
		gameLayer.addChild(particleLayer)
		
		scoreNode.fontSize = 150
		scoreNode.text = "0"
		scoreNode.position = CGPoint(x: size.width / 2, y: (size.height + timerNode.position.y + TimerHeight) / 2 - 75.0)
		
		tilesLayer.addChild(timerNode)
		tilesLayer.addChild(scoreNode)
		
		for x in 0..<NumColumns {
			for y in 0..<NumRows {
				let tile = SKShapeNode()
				tile.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: tileWidth, height: tileWidth)).cgPath
				tile.position = pointForTile(x, row: y)
				tile.fillColor = (x + y) % 2 == 0 ? UIColor(white: 0.7, alpha: 0.8) : UIColor(white: 0.3, alpha: 0.8)
				tile.lineWidth = 0
				tilesLayer.addChild(tile)
			}
		}
	}
	
	override func update(_ currentTime: TimeInterval) {
		self.currentTime = currentTime
		
		if let time = moveStartTime {
			let interval = Float(self.currentTime - time)
			
			if interval > 6.0 {
				swiftTouchesEnded(NSSet(), with: nil)
			}
			else {
				timerNode.setPercentage((6.0 - interval) / 6.0)
			}
		}
	}
}

// Location Utilities
extension GameScene {
	func addNodesForBalls(_ balls: Set<Ball>) {
		for ball in balls {
			let node = BallNode(color: ball.color, width: ballWidth)
			node.position = pointForBall(ball.column, row:ball.row)
			ballsLayer.addChild(node)
			ball.node = node
		}
	}
	
	func addNodesForFalls(_ falls: Set<Fall>) {
		for fall in falls {
			let node = BallNode(color: fall.ball.color, width: ballWidth)
			node.position = pointForBall(fall.ball.column, row:fall.fromRow)
			ballsLayer.addChild(node)
			fall.ball.node = node
		}
	}
	
	func pointForTile(_ column: Int, row: Int) -> CGPoint {
		return CGPoint(x: CGFloat(column) * tileWidth, y: CGFloat(row) * tileWidth)
	}
	
	func pointForBall(_ column: Int, row: Int) -> CGPoint {
		return CGPoint(x: (CGFloat(column) + 0.5) * tileWidth, y: (CGFloat(row) + 0.5) * tileWidth)
	}
	
	func tileAtPoint(_ point: CGPoint) -> (inTile: Bool, column: Int, row: Int) {
		if point.x >= 0 && point.x < CGFloat(NumColumns) * tileWidth && point.y >= 0 && point.y < CGFloat(NumRows) * tileWidth {
			return (true, Int(point.x / tileWidth), Int(point.y / tileWidth))
		}
		else {
			return (false, 0, 0)  // invalid location
		}
	}
}

// UIResponder
extension GameScene {
	@objc func swiftTouchesBegan(_ touches: NSSet, with event: UIEvent?) {
		let touch = touches.allObjects[0] as? UITouch
		let location = touch!.location(in: ballsLayer)
		let (inTile, column, row) = tileAtPoint(location)
		
		if inTile {
			if let ball = board.ballAtColumn(column, row: row) {
				movingBall = ball
				movingBall!.node!.fillColor = movingBall!.node!.fillColor.withAlphaComponent(0.3)
				movingNode = BallNode(color: ball.color, width: ballWidth)
				movingNode!.fillColor = movingNode!.fillColor.withAlphaComponent(0.7)
				movingNode!.position = location
				movingNode!.zPosition = 2
				ballsLayer.addChild(movingNode!)
			}
		}
	}
	
	@objc func swiftTouchesMoved(_ touches: NSSet, with event: UIEvent!) {
		if movingNode == nil {
			return
		}
		
		let touch = touches.anyObject() as! UITouch
		let location = touch.location(in: ballsLayer)
		movingNode!.position = location
		
		let (inTile, column, row) = tileAtPoint(location)
		
		if inTile {
			if moveStartTime == nil {
				moveStartTime = currentTime
			}
			if let ball = board.ballAtColumn(column, row: row) {
				if ball != movingBall {
					if let handler = swapHandler {
						handler(movingBall!, ball)
					}
				}
			}
		}
	}
	
	@objc func swiftTouchesEnded(_ touches: NSSet, with event: UIEvent!) {
		if movingNode == nil {
			return
		}
		
		movingBall!.node!.fillColor = movingBall!.node!.fillColor.withAlphaComponent(1.0)
		movingNode!.removeFromParent()
		movingNode = nil
		moveStartTime = nil
		timerNode.setPercentage(1.0)
		
		if let handler = didEndMovingHandler {
			handler()
		}
	}
	
	@objc func swiftTouchesCancelled(_ touches: NSSet, with event: UIEvent!) {
		swiftTouchesEnded(touches, with: event)
	}
}

// Animations
extension GameScene {
	func animateSwap(_ ball1: Ball, ball2: Ball) {
		let node1 = ball1.node!
		let node2 = ball2.node!
		
		node1.zPosition = 1
		node2.zPosition = 0
		
		let Duration: TimeInterval = 0.1
		
		let move1 = SKAction.move(to: pointForBall(ball1.column, row: ball1.row), duration: Duration)
		move1.timingMode = .easeOut
		node1.run(move1)
		
		let move2 = SKAction.move(to: pointForBall(ball2.column, row: ball2.row), duration: Duration)
		move2.timingMode = .easeOut
		node2.run(move2)
	}
	
	func animateMatchRemoval(_ match: Set<Ball>, completion: @escaping () -> ()) {
		let path = Bundle.main.path(forResource: "spark", ofType: "sks")
		let template = NSKeyedUnarchiver.unarchiveObject(withFile: path!) as! SKEmitterNode
		for ball in match {
			let particle = template.copy() as! SKEmitterNode
			particle.position = CGPoint(x: scoreNode.position.x, y: scoreNode.position.y + 30.0)
			particle.particleColor = ball.color.color
			
			let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
			scaleAction.timingMode = .easeOut
			let moveAction = SKAction.move(to: scoreNode.position, duration: 0.3)
			moveAction.timingMode = .easeOut
			
			ball.node!.run(SKAction.sequence([
				SKAction.group([scaleAction, moveAction]),
				SKAction.run({
					self.particleLayer.addChild(particle)
					particle.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.removeFromParent()]))
				}),
				SKAction.removeFromParent()]))
		}
		run(SKAction.wait(forDuration: 0.3), completion: completion)
	}
	
	func animateFallingBalls(_ falls: [Fall], completion: @escaping () -> ()) {
		var longestDuration: TimeInterval = 0
		let delay = 0.05
		
		for fall in falls {
			let newPoint = pointForBall(fall.ball.column, row: fall.ball.row)
			let node = fall.ball.node!
			let duration = TimeInterval(((node.position.y - newPoint.y) / tileWidth) * 0.1)
			longestDuration = max(longestDuration, duration + delay)
			let moveAction = SKAction.move(to: newPoint, duration: duration)
			moveAction.timingMode = .easeOut
			node.run(SKAction.sequence([SKAction.wait(forDuration: delay), moveAction]))
		}
		run(SKAction.wait(forDuration: longestDuration), completion: completion)
	}
	
	func animateScore(_ score: Int, animate: Bool, completion: @escaping () -> ()) {
		if animate {
			scoreNode.run(SKAction.sequence([
				SKAction.scale(to: 1.2, duration: 0.1),
				SKAction.run({self.scoreNode.text = String(score)}),
				SKAction.scale(to: 1.0, duration: 0.1)]))
			
			run(SKAction.wait(forDuration: 0.2), completion: completion)
		}
		else {
			self.scoreNode.text = String(score)
		}
	}
}
