//
//  GameScene.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import SpriteKit

let TimerHeight: CGFloat = 10.0

class BallNode: SKShapeNode {
	
	required init(coder aDecoder: NSCoder!) {
		super.init(coder: aDecoder)
	}
	
	init(color: BallColor, width: CGFloat) {
		super.init()
		var ovalPath = CGPathCreateMutable();
		CGPathAddArc(ovalPath, nil, CGFloat(0), CGFloat(0), width / 2, CGFloat(0), CGFloat(2 * M_PI), false);
		self.path = ovalPath
		self.fillColor = color.color
	}
}

class TimerNode: SKShapeNode {
	let bar = SKShapeNode()
	
	required init(coder aDecoder: NSCoder!) {
		super.init(coder: aDecoder)
	}
	
	init(size: CGSize) {
		super.init()
		self.path = UIBezierPath(rect: CGRectMake(0, 0, size.width, size.height)).CGPath
		self.lineWidth = 0
		
		let border = SKShapeNode()
		border.path = UIBezierPath(rect: CGRectMake(1, 1, size.width - 2, size.height - 2)).CGPath
		addChild(border)
		
		bar.path = UIBezierPath(rect: CGRectMake(0, 0, size.width - 4, size.height - 4)).CGPath
		bar.position = CGPointMake(2.0, 2.0)
		bar.lineWidth = 0
		bar.fillColor = BallColor.Green.color
		addChild(bar)
	}
	
	func setPercentage(var percentage: Float) {
		percentage = percentage > 1.0 ? 1.0 : percentage
		percentage = percentage < 0.0 ? 0.0 : percentage
		bar.path = UIBezierPath(rect: CGRectMake(CGFloat(0.0), CGFloat(0.0), CGFloat(Float(frame.size.width - 4.0) * percentage), CGFloat(frame.size.height - 4.0))).CGPath
		bar.fillColor = percentage > 0.3 ? BallColor.Green.color : BallColor.Red.color
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
	var moveStartTime: NSTimeInterval?
	
	var swapHandler: ((Ball, Ball) -> ())?
	var didEndMovingHandler: (() -> ())?
	
	var currentTime: NSTimeInterval = 0
	
	required init(coder aDecoder: NSCoder!) {
		tileWidth = 0.0
		timerNode = TimerNode(size: CGSizeMake(320.0, TimerHeight))
		
		super.init(coder: aDecoder)
	}
	
	override init(size: CGSize) {
		tileWidth = size.width / CGFloat(NumColumns)
		timerNode = TimerNode(size: CGSizeMake(size.width, TimerHeight))
		timerNode.position = CGPointMake(0, tileWidth * CGFloat(NumRows))
		
		super.init(size: size)
		
		self.backgroundColor = UIColor.brownColor()
		
		addChild(gameLayer)
		
		gameLayer.addChild(tilesLayer)
		gameLayer.addChild(ballsLayer)
		gameLayer.addChild(particleLayer)
		
		scoreNode.fontSize = 150
		scoreNode.text = "0"
		scoreNode.position = CGPointMake(size.width / 2, (size.height + timerNode.position.y + TimerHeight) / 2 - 75.0)
		
		tilesLayer.addChild(timerNode)
		tilesLayer.addChild(scoreNode)
		
		for x in 0..<NumColumns {
			for y in 0..<NumRows {
				var tile = SKShapeNode()
				tile.path = UIBezierPath(rect: CGRectMake(0, 0, tileWidth, tileWidth)).CGPath
				tile.position = pointForTile(x, row: y)
				tile.fillColor = (x + y) % 2 == 0 ? UIColor(white: 0.7, alpha: 0.8) : UIColor(white: 0.3, alpha: 0.8)
				tile.lineWidth = 0
				tilesLayer.addChild(tile)
			}
		}
	}
	
	override func update(currentTime: NSTimeInterval) {
		self.currentTime = currentTime
		
		if let time = moveStartTime {
			let interval = Float(self.currentTime - time)
			
			if interval > 6.0 {
				touchesEnded(nil, withEvent: nil)
			}
			else {
				timerNode.setPercentage((6.0 - interval) / 6.0)
			}
		}
	}
}

// Location Utilities
extension GameScene {
	func addNodesForBalls(balls: Set<Ball>) {
		for ball in balls {
			let node = BallNode(color: ball.color, width: ballWidth)
			node.position = pointForBall(ball.column, row:ball.row)
			ballsLayer.addChild(node)
			ball.node = node
		}
	}
	
	func addNodesForFalls(falls: Set<Fall>) {
		for fall in falls {
			let node = BallNode(color: fall.ball.color, width: ballWidth)
			node.position = pointForBall(fall.ball.column, row:fall.fromRow)
			ballsLayer.addChild(node)
			fall.ball.node = node
		}
	}
	
	func pointForTile(column: Int, row: Int) -> CGPoint {
		return CGPoint(x: CGFloat(column) * tileWidth, y: CGFloat(row) * tileWidth)
	}
	
	func pointForBall(column: Int, row: Int) -> CGPoint {
		return CGPoint(x: (CGFloat(column) + 0.5) * tileWidth, y: (CGFloat(row) + 0.5) * tileWidth)
	}
	
	func tileAtPoint(point: CGPoint) -> (inTile: Bool, column: Int, row: Int) {
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
	override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
		let touch = touches.anyObject() as UITouch
		let location = touch.locationInNode(ballsLayer)
		let (inTile, column, row) = tileAtPoint(location)
		
		if inTile {
			if let ball = board.ballAtColumn(column, row: row) {
				movingBall = ball
				movingBall!.node!.fillColor = movingBall!.node!.fillColor.colorWithAlphaComponent(0.3)
				movingNode = BallNode(color: ball.color, width: ballWidth)
				movingNode!.fillColor = movingNode!.fillColor.colorWithAlphaComponent(0.7)
				movingNode!.position = location
				movingNode!.zPosition = 2
				ballsLayer.addChild(movingNode)
			}
		}
	}
	
	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
		if movingNode == nil {
			return
		}
		
		let touch = touches.anyObject() as UITouch
		let location = touch.locationInNode(ballsLayer)
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
	
	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
		if movingNode == nil {
			return
		}
		
		movingBall!.node!.fillColor = movingBall!.node!.fillColor.colorWithAlphaComponent(1.0)
		movingNode!.removeFromParent()
		movingNode = nil
		moveStartTime = nil
		timerNode.setPercentage(1.0)
		
		if let handler = didEndMovingHandler {
			handler()
		}
	}
	
	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}
}

// Animations
extension GameScene {
	func animateSwap(ball1: Ball, ball2: Ball) {
		let node1 = ball1.node!
		let node2 = ball2.node!
		
		node1.zPosition = 1
		node2.zPosition = 0
		
		let Duration: NSTimeInterval = 0.1
		
		let move1 = SKAction.moveTo(pointForBall(ball1.column, row: ball1.row), duration: Duration)
		move1.timingMode = .EaseOut
		node1.runAction(move1)
		
		let move2 = SKAction.moveTo(pointForBall(ball2.column, row: ball2.row), duration: Duration)
		move2.timingMode = .EaseOut
		node2.runAction(move2)
	}
	
	func animateMatchRemoval(match: Set<Ball>, completion: () -> ()) {
		let path = NSBundle.mainBundle().pathForResource("spark", ofType: "sks")
		let template = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as SKEmitterNode
		for ball in match {
			let particle = template.copy() as SKEmitterNode
			particle.position = CGPointMake(scoreNode.position.x, scoreNode.position.y + 30.0)
			particle.particleColor = ball.color.color
			
			let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
			scaleAction.timingMode = .EaseOut
			let moveAction = SKAction.moveTo(scoreNode.position, duration: 0.3)
			moveAction.timingMode = .EaseOut
			
			ball.node!.runAction(SKAction.sequence([
				SKAction.group([scaleAction, moveAction]),
				SKAction.runBlock({
					self.particleLayer.addChild(particle)
					particle.runAction(SKAction.sequence([SKAction.waitForDuration(0.2), SKAction.removeFromParent()]))
				}),
				SKAction.removeFromParent()]))
		}
		runAction(SKAction.waitForDuration(0.3), completion: completion)
	}
	
	func animateFallingBalls(falls: [Fall], completion: () -> ()) {
		var longestDuration: NSTimeInterval = 0
		let delay = 0.05
		
		for fall in falls {
			let newPoint = pointForBall(fall.ball.column, row: fall.ball.row)
			let node = fall.ball.node!
			let duration = NSTimeInterval(((node.position.y - newPoint.y) / tileWidth) * 0.1)
			longestDuration = max(longestDuration, duration + delay)
			let moveAction = SKAction.moveTo(newPoint, duration: duration)
			moveAction.timingMode = .EaseOut
			node.runAction(SKAction.sequence([SKAction.waitForDuration(delay), moveAction]))
		}
		runAction(SKAction.waitForDuration(longestDuration), completion: completion)
	}
	
	func animateScore(score: Int, animate: Bool, completion: () -> ()) {
		if animate {
			scoreNode.runAction(SKAction.sequence([
				SKAction.scaleTo(1.2, duration: 0.1),
				SKAction.runBlock({self.scoreNode.text = String(score)}),
				SKAction.scaleTo(1.0, duration: 0.1)]))
			
			runAction(SKAction.waitForDuration(0.2), completion: completion)
		}
		else {
			self.scoreNode.text = String(score)
		}
	}
}
