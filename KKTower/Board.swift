//
//  Board.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/15.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

let NumColumns = 6
let NumRows = 5

class Board {
	var balls = Array2D<Ball>(columns: NumColumns, rows: NumRows)
	
	func ballAtColumn(column: Int, row: Int) -> Ball? {
		assert(column >= 0 && column < NumColumns)
		assert(row >= 0 && row < NumRows)
		return balls[column, row]
	}
	
	func shuffle() -> Set<Ball> {
		var set: Set<Ball>
		set = createInitialBalls()
		
		return set
	}
 
	func createInitialBalls() -> Set<Ball> {
		var set = Set<Ball>()
		
		for row in 0..<NumRows {
			for column in 0..<NumColumns {
				var color : BallColor
				do {
					color = BallColor.random()
				} while (column >= 2 && balls[column - 1, row]?.color == color && balls[column - 2, row]?.color == color) ||
					(row >= 2 && balls[column, row - 1]?.color == color && balls[column, row - 2]?.color == color)
				
				let ball = Ball(column: column, row: row, ballColor: color)
				balls[column, row] = ball
				
				set.addElement(ball)
			}
		}
		return set
	}
	
	func performSwap(ball1: Ball, ball2: Ball) {
		let column1 = ball1.column
		let row1 = ball1.row
		let column2 = ball2.column
		let row2 = ball2.row
		
		balls[column1, row1] = ball2
		ball2.column = column1
		ball2.row = row1
		
		balls[column2, row2] = ball1
		ball1.column = column2
		ball1.row = row2
	}
	
	func detectHorizontalMatches() -> Array<Set<Ball>> {
		var array = Array<Set<Ball>>()
		for row in 0..<NumRows {
			for var column = 0; column < NumColumns - 2 ; {
				if let ball = balls[column, row] {
					let matchColor = ball.color
					if balls[column + 1, row]?.color == matchColor && balls[column + 2, row]?.color == matchColor {
						let set = Set<Ball>()
						do {
							set.addElement(balls[column, row]!)
							++column
						} while column < NumColumns && balls[column, row]?.color == matchColor
						
						array.append(set)
						continue
					}
				}
				++column
			}
		}
		return array
	}
	
	func detectVerticalMatches() -> Array<Set<Ball>> {
		var array = Array<Set<Ball>>()
		for column in 0..<NumColumns {
			for var row = 0; row < NumRows - 2 ; {
				if let ball = balls[column, row] {
					let matchColor = ball.color
					if balls[column, row + 1]?.color == matchColor && balls[column, row + 2]?.color == matchColor {
						let set = Set<Ball>()
						do {
							set.addElement(balls[column, row]!)
							++row
						} while row < NumRows && balls[column, row]?.color == matchColor
						
						array.append(set)
						continue
					}
				}
				++row
			}
		}
		return array
	}
	
	func unionTwoIntersectedSetsInArray(inout array: Array<Set<Ball>>) -> Bool {
		var index1: Int?
		var index2: Int?
		
		find: for i in 0..<(array.count) {
			for j in i+1..<array.count {
				if array[i].intersectsSet(array[j]) {
					index1 = i; index2 = j
					break find
				}
			}
		}
		
		if index1 && index2 {
			var set1 = array.removeAtIndex(index2!)
			var set2 = array.removeAtIndex(index1!)
			array.append(set1.unionSet(set2))
			return true
		}
		return false
	}
	
	func removeMatches() -> Array<Set<Ball>> {
		var array = detectHorizontalMatches() + detectVerticalMatches()
		var result: Bool
		while unionTwoIntersectedSetsInArray(&array) {}
		
		for set in array {
			for ball in set {
				balls[ball.column, ball.row] = nil
			}
		}
		
		return array
	}
	
	func fillHoles() -> (newFalls: Set<Fall>, falls: [Fall]) {
		var newFalls = Set<Fall>()
		var falls = [Fall]()
		
		for column in 0..<NumColumns {
			var topUpIndex = NumRows
			for row in 0..<NumRows {
				if balls[column, row] == nil {
					var fall: Fall?
					for lookup in (row + 1)..<NumRows {
						if let ball = balls[column, lookup] {
							ball.row = row
							balls[column, row] = ball
							balls[column, lookup] = nil
							fall = Fall(ball: ball, fromRow: lookup)
							break
						}
					}
					if !fall {
						balls[column, row] = Ball(column: column, row: row, ballColor: BallColor.random())
						fall = Fall(ball: balls[column, row]!, fromRow: topUpIndex)
						topUpIndex++
						newFalls.addElement(fall!)
					}
					falls.append(fall!)
				}
			}
		}
		
		return (newFalls, falls)
	}
}
