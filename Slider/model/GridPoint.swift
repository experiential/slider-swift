//
//  GridPoint.swift
//  Slider
//
//  Created by James Sanford on 19/06/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

public struct GridPoint: Equatable
{
    var x: Int
    var y: Int
    
    public static func == (lhs: GridPoint, rhs: GridPoint) -> Bool
    {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func isAdjacentTo(point:GridPoint) -> Bool
    {
        return self.gridDistanceTo(point:point) == 1
    }
    
    func gridDistanceTo(point:GridPoint) -> Int
    {
        return abs(self.x - point.x) + abs(self.y - point.y)
    }
    
    public var description: String { return "GridPoint:\(x),\(y)" }
    
    // Directions are encoded as ints from 0-3, such that we can invert (xor with 3) the int value and get its opposite move, i.e. up <-> down, left <-> right. So, moves are coded as: Up: 3 (11), Down: 0 (00), Left: 1 (01), Right: 2 (10) That way we can always avoid quickly find the opposite direction
    func getAdjacentPointIn(direction:Int) -> GridPoint
    {
        // Determine changes in x and y according to move type.
        // Note that it would almost certainly be faster here to create a new GridPoint in each if clause, but it would be less readable and less obvious that we can only modify one of the x or y directions, and only by 1 or -1.
        var dx = 0
        var dy = 0
        if direction == 0 { dy -= 1 }
        else if direction == 1 { dx += 1 }
        else if direction == 2 { dx -= 1 }
        else if direction == 3 { dy += 1 }
        
        return GridPoint(x: self.x + dx, y: self.y + dy)
    }
}

