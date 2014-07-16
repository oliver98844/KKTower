//
//  Set.swift
//  KKTower
//
//  Created by Oliver Huang on 2014/7/15.
//  Copyright (c) 2014年 KKBOX. All rights reserved.
//

class Set<T: Hashable>: Sequence, Printable {
	var dictionary = Dictionary<T, Bool>()
	
	func addElement(newElement: T) {
		dictionary[newElement] = true
	}
	
	func removeElement(element: T) {
		dictionary[element] = nil
	}
	
	func containsElement(element: T) -> Bool {
		return dictionary[element] != nil
	}
	
	func allElements() -> Array<T> {
		return Array(dictionary.keys)
	}
	
	func unionSet(aSet: Set<T>) -> Set<T> {
		var combined = Set<T>()
		
		for obj in self {
			combined.addElement(obj)
		}
		for obj in aSet {
			combined.addElement(obj)
		}
		return combined
	}
	
	func intersectsSet(aSet: Set<T>) -> Bool {
		for obj in self {
			if aSet.containsElement(obj) {
				return true
			}
		}
		return false
	}
	
	func count() -> Int {
		return dictionary.count
	}
	
	func generate() -> IndexingGenerator<Array<T>> {
		return allElements().generate()
	}
	
	var description: String {
		return Array(dictionary.keys).description
	}
}
