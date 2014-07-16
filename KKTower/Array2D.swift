//
//  Array2D.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/15.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

class Array2D<T> {
	let columns : Int
	let rows : Int
	var array: Array<T?>  // private
 
	init(columns: Int, rows: Int) {
		self.columns = columns
		self.rows = rows
		array = Array<T?>(count: rows*columns, repeatedValue: nil)
	}
 
	subscript(column: Int, row: Int) -> T? {
		get {
			return array[row*columns + column]
		}
		set {
			array[row*columns + column] = newValue
		}
	}
}
