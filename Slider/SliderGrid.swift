//
//  SliderGrid.swift
//  Slider
//
//  Created by James Sanford on 04/01/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

class SliderGrid
{
    var gridSize: GridSize
    var points: [[Tile?]]
    var space: GridPoint
    var tilesInHomePosition = 0
    let originalSpace: GridPoint
    
    init(size:GridSize)
    {
        self.gridSize = size
        let space = GridPoint(x: size.width - 1, y: size.height - 1)
        self.space = space
        self.originalSpace = space
        self.points = (0..<size.height).map
            {
                y in (0..<size.width).map
                    {
                        x in
                        if(x == space.x && y == space.y)
                        {
                            return nil
                        }
                        return Tile(position: GridPoint(x: x,y: y), homePosition: GridPoint(x: x,y: y))
                }
        }
        
        // All tiles should be in home (grid-complete) position, so set count to maximum
        tilesInHomePosition = size.width * size.height - 1
    }
    
    init(originalGrid:SliderGrid)
    {
        self.gridSize = originalGrid.gridSize // This will create a copy of 'gridSize'
        self.space = originalGrid.space // This will create a copy of 'space'
        self.originalSpace = originalGrid.originalSpace // This will create a copy of 'space'
        self.tilesInHomePosition = originalGrid.tilesInHomePosition
        self.points = (0..<originalGrid.gridSize.height).map
            {
                y in (0..<originalGrid.gridSize.width).map
                    {
                        x in
                        if(x == originalGrid.space.x && y == originalGrid.space.y)
                        {
                            return nil
                        }
                        return Tile(originalTile: originalGrid.points[y][x]!)
                }
        }
    }
    
    func getTileAt(point:GridPoint) -> Tile?
    {
        if gridPointIsOutOfBounds(point: point) { return nil }

        return points[point.y][point.x]
    }
    
    func findTileWithHomePosition(point:GridPoint) -> Tile?
    {
        if gridPointIsOutOfBounds(point: point) { return nil }
        
        for i in 0..<gridSize.height
        {
            for j in 0..<gridSize.width
            {
                if let thisTile = points[i][j]
                {
                    if thisTile.homePosition == point
                    {
                        return thisTile
                    }
                }
            }
        }
        
        return nil
    }
    
    func gridPointIsOutOfBounds(point:GridPoint) -> Bool
    {
        return point.x > gridSize.width - 1 || point.x < 0 || point.y > gridSize.height - 1 || point.y < 0
    }
    
    func moveTile(from:GridPoint) -> Bool
    {
        // Check 'from point' is within bounds
        if(from.x < 0 || from.y < 0 || from.x >= self.gridSize.width || from.y >= self.gridSize.height) { return false }
        
        let tile = points[from.y][from.x]
        if(tile != nil)
        {
            // Check space is empty
            if(points[space.y][space.x] != nil) { return false }
            
            // Check 'from' point is adjacent to space
            if(abs(from.x - space.x) + abs(from.y - space.y) != 1) { return false }
            
            // We're definitely going to move the tile, so...
            // Check whether we're about to move it out of its home position, and reduce the counter if so
            if(tile!.position == tile!.homePosition)
            {
                tilesInHomePosition -= 1
            }
            
            // Move tile in data structure
            points[from.y][from.x] = nil
            points[space.y][space.x] = tile!
            tile!.position = GridPoint(x:space.x, y:space.y)
            space = from
            
            // Check whether we've moved to tile into its home position, and increase the counter if so
            if(tile!.position == tile!.homePosition)
            {
                tilesInHomePosition += 1
            }
        }
        else
        {
            return false
        }
        
        return true
    }
    
    func scramble(moves:Int)
    {
        // Encode moves as ints from 0-3, such that we can invert (xor with 3) the int value and get its opposite
        // move, i.e. up <-> down, left <-> right
        // So, moves are coded as: Up: 3 (11), Down: 0 (00), Left: 1 (01), Right: 2 (10)
        // That way we can always avoid cancelling the previous move
        var lastMove = 0
        for i in 0..<moves
        {
            var thisMove = Int.random(in: 0...2) // There are three possible moves that don't cancel the last move
            let oppositeMove = lastMove ^ 3 // Determine the one move that would cancel the previous move using XOR
            if(thisMove >= oppositeMove) { thisMove += 1 } // Redistribute the random move set to avoid cancelling move
            
            // Determine changes in x and y according to move type
            var dx = 0
            var dy = 0
            if thisMove == 0 { dy -= 1 }
            if thisMove == 1 { dx += 1 }
            if thisMove == 2 { dx -= 1 }
            if thisMove == 3 { dy += 1 }
            
            if self.moveTile(from:GridPoint(x: space.x + dx, y: space.y + dy))
            {
                // Move was made successfully, so record this move as our last move for the next loop iteration
                lastMove = thisMove
            }
        }
    }
    
    /*func copy(with zone: NSZone? = nil) -> Any
     {
     var newGrid = SliderGrid(size:self.gridSize)
     
     newGrid.space = self.space
     newGrid.points = (0..<gridSize.height).map
     {
     y in (0..<gridSize.width).map
     {
     x in
     if(x == space.x && y == space.y)
     {
     return nil
     }
     return self.points[y][x]!.copy()
     }
     }
     
     return newGrid
     }*/
}

class Tile: NSObject, NSCopying
{
    var position: GridPoint
    var homePosition: GridPoint
    
    init(position:GridPoint, homePosition:GridPoint)
    {
        self.position = position
        self.homePosition = homePosition
    }
    
    init(originalTile:Tile)
    {
        self.position = originalTile.position
        self.homePosition = originalTile.homePosition
    }
    
    func getIdentifier() -> String
    {
        return String(describing: self.homePosition.x) + "-" + String(describing: self.homePosition.y)
    }
    
    func copy(with zone: NSZone? = nil) -> Any
    {
        return Tile(position:self.position, homePosition:self.homePosition)
    }
    
    func isAdjacentTo(tile:Tile) -> Bool
    {
        return self.position.isAdjacentTo(point: tile.position)
    }
}

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
}

public struct GridSize
{
    let width: Int
    let height: Int
}

