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
    var changedSinceLastMove = false
    var locked = false
    
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
        if (self.locked || from.x < 0 || from.y < 0 || from.x >= self.gridSize.width || from.y >= self.gridSize.height) { return false }
        
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

        // Lock the grid from any moves while we do this
        self.locked = true
        
        // Check current position of specified tile and space: if they are not *both* an even or odd number of moves from their original positions, we have swap two adjacent tiles to ensure the grid remains solvable
        let spaceDistance = abs(space.x - originalSpace.x) + abs(space.y - originalSpace.y)
        let tileDistance = abs(tile.position.x - tile.homePosition.x) + abs(tile.position.y - tile.homePosition.y)
        
        // Create a new tile to replace the space
        let newTile = Tile(grid: self, position: space, homePosition: originalSpace)
        points[space.y][space.x] = newTile
        space = tile.position
        originalSpace = tile.homePosition
        points[tile.position.y][tile.position.x] = nil
        
        if let viewController = self.viewController
        {
            viewController.spaceSwappedWithTile(oldTile:tile, newTile:newTile)
        }
        
        if spaceDistance % 2 != tileDistance % 2
        {
            // We also need to swap two tiles to make the grid solvable. So that this doesn't seem totally random, let's swap the new tile we just created with some neighbouring tile.
            var tileToSwap = tile
            var tileFound = false
            for direction in 0...3
            {
                let newPoint = newTile.position.getAdjacentPointIn(direction: direction)
                if !self.gridPointIsOutOfBounds(point: newPoint) && newPoint != self.space
                {
                    tileToSwap = self.getTileAt(point: newPoint)! // We checked for out of bounds and space, so must be a tile and therefore safe to unwrap.
                    tileFound = true
                    break
                }
                else
                {
                    continue
                }
            }
            
            // If we found a neighbouring tile (this should always happen) then we can swap the tiles
            if tileFound
            {
                let newTilePosition = newTile.position
                let tileToSwapPosition = tileToSwap.position
                points[newTilePosition.y][newTilePosition.x] = tileToSwap
                points[tileToSwapPosition.y][tileToSwapPosition.x] = newTile
                tileToSwap.position = newTilePosition
                newTile.position = tileToSwapPosition

                // Update view controller on the swap
                if let viewController = self.viewController
                {
                    viewController.tileSwappedWithTile(tile1:newTile, tile2:tileToSwap)
                }
            }
        }

        recalculateTilesInHomePosition()
        
        changedSinceLastMove = true
        self.locked = false
    }
    
    func recalculateTilesInHomePosition()
    {
        self.tilesInHomePosition = 0
        
        for i in 0..<gridSize.height
        {
            for j in 0..<gridSize.width
            {
                if let thisTile = points[i][j]
                {
                    if thisTile.homePosition == thisTile.position
                    {
                        self.tilesInHomePosition += 1
                    }
                }
            }
        }
    }
}

