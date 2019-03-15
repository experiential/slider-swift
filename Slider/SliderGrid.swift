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
    var game: Game
    var gridSize: GridSize
    var points: [[Tile?]] = [[]]
    var space: GridPoint
    var tilesInHomePosition = 0
    var originalSpace: GridPoint
    var changedSinceLastMove: Bool = false
    
    var viewController: GridViewController?
    
    init(size:GridSize, space:GridPoint, game:Game)
    {
        self.gridSize = size
        self.space = space
        self.originalSpace = space
        self.game = game
        self.points = (0..<size.height).map
        {
            y in (0..<size.width).map
            {
                x in
                if(x == space.x && y == space.y)
                {
                    return nil
                }
                return Tile(grid:self, position: GridPoint(x: x,y: y), homePosition: GridPoint(x: x,y: y))
            }
        }
        
        // All tiles should be in home (grid-complete) position, so set count to maximum
        tilesInHomePosition = size.width * size.height - 1
    }
    
    init(originalGrid:SliderGrid)
    {
        self.gridSize = originalGrid.gridSize // This will create a copy of 'gridSize'
        self.space = originalGrid.space // This will create a copy of 'space' etc....
        self.originalSpace = originalGrid.originalSpace
        self.game = originalGrid.game
        self.points = (0..<originalGrid.gridSize.height).map
        {
            y in (0..<originalGrid.gridSize.width).map
            {
                x in
                if(x == originalGrid.space.x && y == originalGrid.space.y)
                {
                    return nil
                }
                var newTile = Tile(originalTile: originalGrid.points[y][x]!)
                newTile.grid = self
                return newTile
            }
        }
        self.tilesInHomePosition = originalGrid.tilesInHomePosition
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
        if (from.x < 0 || from.y < 0 || from.x >= self.gridSize.width || from.y >= self.gridSize.height) { return false }
        
        let tile = points[from.y][from.x]
        if tile != nil
        {
            // Check space is empty
            if points[space.y][space.x] != nil { return false }
            
            // Check 'from' point is adjacent to space
            if !from.isAdjacentTo(point: space) { return false }
            
            if let tileEffect = tile!.tileEffect
            {
                if !tileEffect.tileWillMove() { return false }
            }
            
            // We're definitely going to move the tile, so...
            // Unset the 'changed' flag
            changedSinceLastMove = false
            
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
            if tile!.position == tile!.homePosition
            {
                tilesInHomePosition += 1
            }

            tile!.tileEffect?.tileDidMove()
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
            
            if self.moveTile(from:space.getAdjacentPointIn(direction: thisMove))
            {
                // Move was made successfully, so record this move as our last move for the next loop iteration
                lastMove = thisMove
            }
        }
    }
    
    func changeSpaceToTile(tile:Tile)
    {
        print("changeSpaceToTile called")
        if tile.grid !== self { return }
        
        // Check current position of specified tile and space: if they are an even number of moves apart, we have to pick a different tile, one that is an odd number of moves from the space... in this case we pick an adjacent one
        
        let spaceDistance = abs(space.x - originalSpace.x) + abs(space.y - originalSpace.y)
        var tileToSwap = tile
        var tileFound = false
        for direction in -1...3 // -1 will stand for the specified tile, the rest for tiles in each of the four directions
        {
            if direction >= 0
            {
                let newPoint = tile.position.getAdjacentPointIn(direction: direction)
                if !self.gridPointIsOutOfBounds(point: newPoint) && newPoint != self.space
                {
                    tileToSwap = self.getTileAt(point: newPoint)! // We checked for out of bounds and space, so must be a tile and therefore safe to unwrap.
                }
                else
                {
                    continue
                }
            }
            print("TileSwap: Checking tile at ",tileToSwap.position.x,",",tileToSwap.position.y)

            let tileDistance = abs(tileToSwap.position.x - tileToSwap.homePosition.x) + abs(tileToSwap.position.y - tileToSwap.homePosition.y)
            if spaceDistance % 2 == tileDistance % 2
            {
                tileFound = true
                break
            }
            else
            {
                print("TileSwap: Can't swap with tile at ",tileToSwap.position.x,",",tileToSwap.position.y)
            }
        }
        
        // Check that we actually found a tile that we can swap without making the grid unsolvable
        if !tileFound { return }
        print("TileSwap: Picked tile at ",tileToSwap.position.x,",",tileToSwap.position.y)

        // Create a new tile to replace the space
        let newTile = Tile(grid: self, position: space, homePosition: originalSpace)
        points[space.y][space.x] = newTile
        space = tileToSwap.position
        originalSpace = tileToSwap.homePosition
        points[tileToSwap.position.y][tileToSwap.position.x] = nil
        
        if let viewController = self.viewController
        {
            viewController.spaceSwappedWithTile(oldTile:tileToSwap, newTile:newTile)
        }
        
        if newTile.position != newTile.homePosition
        {
            tilesInHomePosition -= 1
        }
        
        changedSinceLastMove = true
    }
}

class Tile: NSObject, NSCopying
{
    var grid: SliderGrid
    var position: GridPoint
    var homePosition: GridPoint
    var tileEffect: TileEffect? = nil
    var viewController: TileViewController?
    
    init(grid: SliderGrid, position:GridPoint, homePosition:GridPoint)
    {
        self.grid = grid
        self.position = position
        self.homePosition = homePosition
    }
    
    init(originalTile:Tile)
    {
        self.grid = originalTile.grid
        self.position = originalTile.position
        self.homePosition = originalTile.homePosition
    }
    
    func getIdentifier() -> String
    {
        return String(describing: self.homePosition.x) + "-" + String(describing: self.homePosition.y)
    }
    
    func copy(with zone: NSZone? = nil) -> Any
    {
        return Tile(grid:self.grid, position:self.position, homePosition:self.homePosition)
    }
    
    func isAdjacentTo(tile:Tile) -> Bool
    {
        return self.position.isAdjacentTo(point: tile.position)
    }
}

// Base class for different types of tile bonus special effect
public class TileEffect
{
    var tile: Tile
    
    init(tile:Tile)
    {
        self.tile = tile
    }
    
    func tileWillMove() -> Bool { return true; }
    
    func tileDidMove() { }
}

// This TileEffect class switches the affected tile with the space: the space becomes the tile that would have existed at the place in the initial (complete) grid state, and the affected tile becomes the space.
// NB! This must only be used on tiles that are an *odd number* of moves from the space in the completed grid state. Otherwise the grid becomes unsolvable.
public class SpaceSwitchTileEffect: TileEffect
{
    override func tileDidMove()
    {
        if tile.position == tile.homePosition
        {
            // Find the equivalent of this tile in the other (or the next) grid
            let opponentGrid = tile.grid.game.getOpponentGridFor(grid: tile.grid)
            if let opponentGrid = opponentGrid
            {
                // Find the tile
                let otherTile = opponentGrid.findTileWithHomePosition(point: tile.homePosition)
                
                // Swap space with this tile
                if otherTile != nil { opponentGrid.changeSpaceToTile(tile:otherTile!) }
            }

            // Remove the tile effect
            tile.viewController?.removeTileEffect(effect:self)
        }
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

public struct GridSize
{
    let width: Int
    let height: Int
}

