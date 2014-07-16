//
//  GameScene.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import SpriteKit

class BallNode: SKShapeNode {
	let circle: SKShapeNode
	
	init(color: BallColor, width: CGFloat) {
		self.circle = SKShapeNode()
		
		super.init()
		
		self.path = UIBezierPath(rect: CGRectMake(0, 0, width, width)).CGPath
		self.lineWidth = 0
		self.circle.path = UIBezierPath(ovalInRect: CGRectInset(frame, 2, 2)).CGPath
		self.circle.fillColor = color.color
		self.addChild(circle)
	}
}

class GameScene: SKScene {
	var board: Board!
	
	let ballEdge: CGFloat
	
	let gameLayer = SKNode()
	let ballsLayer = SKNode()
	let tilesLayer = SKNode()
	
	var movingNode: BallNode?
	var movingBall: Ball?
	
	var swapHandler: ((Ball, Ball) -> ())?
	var didEndMovingHandler: (() -> ())?
	
	init(size: CGSize) {
		ballEdge = size.width / CGFloat(NumColumns)
		
		super.init(size: size)
		
		self.backgroundColor = UIColor.brownColor()
		
		addChild(gameLayer)
		
		gameLayer.addChild(tilesLayer)
		gameLayer.addChild(ballsLayer)
		
		for x in 0..<NumColumns {
			for y in 0..<NumRows {
				var tile = SKShapeNode()
				tile.path = UIBezierPath(rect: CGRectMake(0, 0, ballEdge, ballEdge)).CGPath
				tile.position = pointForPosition(x, row: y)
				tile.fillColor = (x + y) % 2 == 0 ? UIColor(white: 0.7, alpha: 0.8) : UIColor(white: 0.3, alpha: 0.8)
				tile.lineWidth = 0
				tilesLayer.addChild(tile)
			}
		}
	}
}

// Location Utilities
extension GameScene {
	func addNodesForBalls(balls: Set<Ball>) {
		for ball in balls {
			let node = BallNode(color: ball.color, width: ballEdge)
			node.position = pointForPosition(ball.column, row:ball.row)
			ballsLayer.addChild(node)
			ball.node = node
		}
	}
	
	func addNodesForFalls(falls: Set<Fall>) {
		for fall in falls {
			let node = BallNode(color: fall.ball.color, width: ballEdge)
			node.position = pointForPosition(fall.ball.column, row:fall.fromRow)
			ballsLayer.addChild(node)
			fall.ball.node = node
		}
	}
	
	func pointForPosition(column: Int, row: Int) -> CGPoint {
		return CGPoint(x: CGFloat(column) * ballEdge, y: CGFloat(row) * ballEdge)
	}
	
	func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
		if point.x >= 0 && point.x < CGFloat(NumColumns) * ballEdge && point.y >= 0 && point.y < CGFloat(NumRows) * ballEdge {
			return (true, Int(point.x / ballEdge), Int(point.y / ballEdge))
		} else {
			return (false, 0, 0)  // invalid location
		}
	}
}

// UIResponder
extension GameScene {
	override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
		let touch = touches.anyObject() as UITouch
		let location = touch.locationInNode(ballsLayer)
		let (success, column, row) = convertPoint(location)
		
		if success {
			if let ball = board.ballAtColumn(column, row: row) {
				movingBall = ball
				movingBall!.node!.circle.fillColor = movingBall!.node!.circle.fillColor.colorWithAlphaComponent(0.3)
				movingNode = BallNode(color: ball.color, width: ballEdge)
				movingNode!.circle.fillColor = movingNode!.circle.fillColor.colorWithAlphaComponent(0.7)
				movingNode!.position = CGPointMake(location.x - ballEdge / 2, location.y - ballEdge / 2)
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
		movingNode!.position = CGPointMake(location.x - ballEdge / 2, location.y - ballEdge / 2)
		
		let (success, column, row) = convertPoint(location)
		
		if success {
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
		
		movingBall!.node!.circle.fillColor = movingBall!.node!.circle.fillColor.colorWithAlphaComponent(1.0)
		movingNode!.removeFromParent()
		movingNode = nil
		
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
		
		let move1 = SKAction.moveTo(pointForPosition(ball1.column, row: ball1.row), duration: Duration)
		move1.timingMode = .EaseOut
		node1.runAction(move1)
		
		let move2 = SKAction.moveTo(pointForPosition(ball2.column, row: ball2.row), duration: Duration)
		move2.timingMode = .EaseOut
		node2.runAction(move2)
	}
	
	func animateMatchesRemoval(matches: Array<Set<Ball>>, completion: () -> ()) {
		var longestDuration: NSTimeInterval = 0
		for (index ,set) in enumerate(matches) {
			let delay = 0.05 + 0.35 * NSTimeInterval(index)
			longestDuration = max(longestDuration, 0.3 + delay)
			for ball in set {
				
				let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
				scaleAction.timingMode = .EaseOut
				ball.node!.runAction(SKAction.sequence([SKAction.waitForDuration(delay), scaleAction, SKAction.removeFromParent()]))
			}
		}
		runAction(SKAction.waitForDuration(longestDuration), completion: completion)
	}
	
	func animateFallingBalls(falls: [Fall], completion: () -> ()) {
		var longestDuration: NSTimeInterval = 0
		let delay = 0.05
		
		for fall in falls {
			let newPoint = pointForPosition(fall.ball.column, row: fall.ball.row)
			let node = fall.ball.node!
			let duration = NSTimeInterval(((node.position.y - newPoint.y) / ballEdge) * 0.1)
			longestDuration = max(longestDuration, duration + delay)
			let moveAction = SKAction.moveTo(newPoint, duration: duration)
			moveAction.timingMode = .EaseOut
			node.runAction(SKAction.sequence([SKAction.waitForDuration(delay), moveAction]))
		}
		runAction(SKAction.waitForDuration(longestDuration), completion: completion)
	}
}
