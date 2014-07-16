//
//  Fall.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/16.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

class Fall: Hashable, Printable {
	let ball: Ball
	let fromRow: Int
	
	init(ball: Ball, fromRow: Int) {
		self.ball = ball
		self.fromRow = fromRow
	}
	
	var description: String {
		return "Fall(\(ball) to row:\(fromRow))"
	}
	
	var hashValue: Int {
		return fromRow * 100 + ball.hashValue
	}
}

func ==(lhs: Fall, rhs: Fall) -> Bool {
	return lhs.ball == rhs.ball && lhs.fromRow == rhs.fromRow
}
