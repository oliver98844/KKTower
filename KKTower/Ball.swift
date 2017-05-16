//
//  KKBall.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/7.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

import SpriteKit
import UIKit

enum BallColor: Int, CustomStringConvertible {
	case blue = 0, red, green, yellow, purple, pink
	var color: UIColor {
		let colors = [
			UIColor(red: 0.337, green: 0.662, blue: 0.976, alpha: 1.0),
			UIColor(red: 0.776, green: 0.156, blue: 0.090, alpha: 1.0),
			UIColor(red: 0.447, green: 0.745, blue: 0.286, alpha: 1.0),
			UIColor(red: 0.956, green: 0.823, blue: 0.243, alpha: 1.0),
			UIColor(red: 0.698, green: 0.431, blue: 0.874, alpha: 1.0),
			UIColor(red: 0.917, green: 0.368, blue: 0.356, alpha: 1.0)]
		return colors[self.rawValue]
	}
	static func random() -> BallColor {
		return BallColor(rawValue: Int(arc4random_uniform(6)))!
	}
	var description: String {
		let names = ["Blue", "Red", "Green", "Yellow", "Purple", "Pink"]
		return names[self.rawValue]
	}
}

class Ball: Hashable, CustomStringConvertible {
	var column: Int
	var row: Int
	let color: BallColor
	var node: BallNode?
	
	init(column: Int, row: Int, ballColor: BallColor) {
		self.column = column
		self.row = row
		self.color = ballColor
	}
	
	var description: String {
		return "Ball(\(row), \(column), \(color))"
	}
	
	var hashValue: Int {
		return row * 10 + column
	}
}

func ==(lhs: Ball, rhs: Ball) -> Bool {
	return lhs.column == rhs.column && lhs.row == rhs.row
}
