//
//  AIGridSolver.swift
//  Slider
//
//  Created by James Sanford on 04/01/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

class AIGridSolver
{
    var gridController:GridViewController
    var grid:SliderGrid
    var timer:Timer?
    var lastMove = 0
    var plan = AIMoveQueue()
    var tileFlags = [Tile: String]()
    
    
    init(gridController:GridViewController)
    {
        self.gridController = gridController
        self.grid = gridController.grid
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.makeAMove), userInfo: nil, repeats: true)
    }
    
    @objc func makeAMove()
    {
        if plan.isEmpty
        {
            // No plan, so we need to make one
            print("Creating plan...")
            var (nextDest, nextTile) = self.getNextTile()
            if nextTile == nil || nextDest == nil
            {
                // Grid is complete so just return
                return
            }
            print("Next tile is...",nextTile!.getIdentifier() )
            
            // Check direction we want the tile to go in
            let pos = nextTile!.position
            let dest = nextDest!
            var spaceDest : GridPoint
            if(pos.x < dest.x)
            {
                // Tile is to the left of its destination, so move space to the right of the tile
                spaceDest = GridPoint(x:pos.x + 1, y:pos.y)
            }
            else if(pos.x > dest.x)
            {
                // Tile is to the right of its destination, so move space to the left of the tile
                spaceDest = GridPoint(x:pos.x - 1, y:pos.y)
            }
            else
            {
                // Tile is below its destination, so move space to point above tile
                spaceDest = GridPoint(x:pos.x, y:pos.y - 1)
            }
            print("Space destination: x:",spaceDest.x," y:",spaceDest.y)
            
            // Check for end of row
            var pos2:GridPoint? = nil
            if nextTile!.homePosition.x == grid.gridSize.width - 2
            {
                print("Tile is penultimate in row")
                if(nextTile!.position.x == nextTile!.homePosition.x + 1 && nextTile!.position.y == nextTile!.homePosition.y)
                {
                    print("Tile is in end of row position")
                    let possibleEndTile = grid.points[nextTile!.homePosition.y + 1][nextTile!.homePosition.x + 1]
                    if let possibleEndTile = possibleEndTile
                    {
                        print("Tile below end of row position exists")
                        if possibleEndTile.position.x == possibleEndTile.homePosition.x && possibleEndTile.position.y == possibleEndTile.homePosition.y + 1
                        {
                            print("End of row move detected!")
                            pos2 = possibleEndTile.position
                        }
                    }
                }
            }
            
            if(grid.space != spaceDest)
            {
                // Move space to destination point
                var space = grid.space
                while(space != spaceDest && plan.count < 50)
                {
                    let dx = spaceDest.x - space.x
                    let dy = spaceDest.y - space.y
                    
                    var newSpace = space
                    if(abs(dx) > abs(dy))
                    {
                        newSpace.x += Int(dx/abs(dx))
                    }
                    else
                    {
                        newSpace.y += Int(dy/abs(dy))
                    }
                    
                    //if newSpace == pos || (pos2 != nil && newSpace == pos2) // Will this move affect the tile we're trying to move?
                    var tileToMove = grid.points[newSpace.y][newSpace.x]
                    if tileToMove != nil && (tileFlags[tileToMove!] == "complete" || tileFlags[tileToMove!] == "tileToMove")
                    {
                        print("TILE FLAG ",tileFlags[tileToMove!]," for tile at ", newSpace.x, ":", newSpace.y)
                        // Musn't move tile, so must go around
                        if newSpace.x != space.x
                        {
                            newSpace.x = space.x
                            
                            // Trying to move left/right, so check whether up or down is preferred (or space is at top/bottom of grid)
                            if space.y != grid.gridSize.height - 1 && (dy >= 0 || space.y == 0)
                            {
                                newSpace.y = space.y + 1
                            }
                            else // Divert up
                            {
                                newSpace.y = space.y - 1
                            }
                        }
                        else
                        {
                            newSpace.y = space.y
                            
                            // Trying to move up/down, so check whether left or right is preferred (or space is at far left/right of grid)
                            if space.x != grid.gridSize.width - 1 && (dx >= 0 || space.x == 0) // >= because if dx is zero, we usually want to divert to the right
                            {
                                newSpace.x = space.x + 1
                            }
                            else // Divert to left
                            {
                                newSpace.x = space.x - 1
                            }
                        }
                        
                    }
                    
                    space = newSpace
                    plan.addToQueue(point: space)
                }
                
            }
            
            // Move tile into space
            plan.addToQueue(point: pos)
        }
        
        // Make next move in plan
        let nextMove = plan.getNext()
        if let nextMove = nextMove { _ = gridController.moveTile(from:nextMove) }
        
    }
    
    func getNextTile() -> (dest: GridPoint?, tile: Tile?)
    {
        // Scan grid for first space that is missing its correct tile
        var nextDestination:GridPoint? = nil
        var nextTileHome:GridPoint? = nil // The home position of the tile we will want to move
        var nextTile:Tile? = nil
        var x = 0
        var y = 0 // Start from top left corner (for now)
        while(nextDestination == nil)
        {
            if(grid.points[y][x] != nil)
            {
                var thisTile = grid.points[y][x]!
                if thisTile.position != thisTile.homePosition
                {
                    if x == (grid.gridSize.width - 2) // Second last tile in row
                    {
                        var tileToRight = grid.points[y][x + 1]
                        if let tileToRight = tileToRight
                        {
                            if tileToRight.homePosition == GridPoint(x:x, y:y) // If tile to the right is (ultimately) meant to go here
                            {
                                // Then the tile to the right may be in the right place for now
                                var tileToRightDown = grid.points[y + 1][x + 1]
                                if let tileToRightDown = tileToRightDown
                                {
                                    if tileToRightDown.homePosition == GridPoint(x:x + 1, y:y)
                                    {
                                        // Both second last tile and last tile are in position for final move to complete row
                                        print("PLAN: Last two tiles in position, move into place and complete row")
                                        nextDestination = GridPoint(x:x, y:y)
                                        nextTileHome = GridPoint(x:x, y:y)
                                        tileFlags[tileToRight] = "complete"
                                        tileFlags[tileToRightDown] = "complete"
                                    }
                                    else
                                    {
                                        // Last tile needs to be moved into position
                                        print("PLAN: Move last row tile into end of row below")
                                        nextDestination = GridPoint(x:x + 1, y:y + 1)
                                        nextTileHome = GridPoint(x:x + 1, y:y)
                                        
                                        tileFlags[tileToRight] = "complete" // Set the flag for penultimate tile
                                    }
                                }
                            }
                            else
                            {
                                // Tile to the right is not the penultimate row tile, so specify that penultimate row tile is to move to position to the right (in preparation for row completion move)
                                print("PLAN: Move penultimate row tile to end of row")
                                nextDestination = GridPoint(x:x + 1, y:y)
                                nextTileHome = GridPoint(x:x, y:y)
                            }
                        }
                        else
                        {
                            // The space is in the position to the right
                            print("PLAN: Space is at end of row, move penultimate row tile to end of row")
                            nextDestination = GridPoint(x:x + 1, y:y)
                            nextTileHome = GridPoint(x:x, y:y)
                        }
                    }
                    else if x == (grid.gridSize.width - 1) // Last tile in row
                    {
                        var tileBelow = grid.points[y + 1][x]
                        if let tileBelow = tileBelow
                        {
                            if tileBelow.homePosition == GridPoint(x:x, y:y) // If tile below is (ultimately) meant to go here
                            {
                                // Last tiles need to be moved into position
                                print("PLAN: Last two tiles in position, move final tile into end of row")
                                nextDestination = GridPoint(x:x, y:y)
                                nextTileHome = GridPoint(x:x, y:y)
                                //tileFlags[thisTile] = "complete"
                            }
                            else
                            {
                                print("PLAN: Final tile not in position, move final tile into end of row below")
                                nextDestination = GridPoint(x:x, y:y + 1)
                                nextTileHome = GridPoint(x:x, y:y)
                            }
                        }
                        else
                        {
                            print("PLAN: Space is at end of row below, move final row tile there instead")
                            // The space is in the position below
                            nextDestination = GridPoint(x:x, y:y + 1)
                            nextTileHome = GridPoint(x:x, y:y)
                        }
                    }
                    else
                    {
                        nextDestination = GridPoint(x:x, y:y)
                        nextTileHome = GridPoint(x:x, y:y)
                    }
                }
            }
            else
            {
                // This is the space
                if x == (grid.gridSize.width - 2) // Second last tile in row?
                {
                    var tileToRight = grid.points[y][x + 1]
                    if let tileToRight = tileToRight
                    {
                        if tileToRight.homePosition == GridPoint(x:x, y:y) // If tile to the right is (ultimately) meant to go here
                        {
                            // Then the tile to the right may be in the right place for now
                            var tileToRightDown = grid.points[y + 1][x + 1]
                            if let tileToRightDown = tileToRightDown
                            {
                                if tileToRightDown.homePosition == GridPoint(x:x + 1, y:y)
                                {
                                    // Both second last tile and last tile are in position for final move to complete row
                                    print("PLAN: Last two tiles in position, move into place and complete row")
                                    nextDestination = GridPoint(x:x, y:y)
                                    nextTileHome = GridPoint(x:x, y:y)
                                    tileFlags[tileToRight] = nil
                                    tileFlags[tileToRightDown] = nil
                                }
                                else
                                {
                                    // Last tile needs to be moved into position
                                    print("PLAN: Move last row tile into end of row below")
                                    nextDestination = GridPoint(x:x + 1, y:y + 1)
                                    nextTileHome = GridPoint(x:x + 1, y:y)
                                    
                                    tileFlags[tileToRight] = "complete" // Set the flag for penultimate tile
                                }
                            }
                        }
                        else
                        {
                            // Tile to the right is not the penultimate row tile, so specify that penultimate row tile is to move to position to the right (in preparation for row completion move)
                            print("PLAN: Move penultimate row tile to end of row")
                            nextDestination = GridPoint(x:x + 1, y:y)
                            nextTileHome = GridPoint(x:x, y:y)
                        }
                    }
                    else
                    {
                        // The space is in the position to the right
                        print("PLAN: Space is at end of row, move penultimate row tile to end of row")
                        nextDestination = GridPoint(x:x + 1, y:y)
                        nextTileHome = GridPoint(x:x, y:y)
                    }
                }
                else
                {
                    nextDestination = GridPoint(x:x, y:y)
                    nextTileHome = GridPoint(x:x, y:y)
                }
            }
            
            if(nextDestination == nil)
            {
                // Tile is in home position so mark the tile  as 'not to be moved' and increment to next
                if grid.points[y][x] != nil
                {
                    var thisTile:Tile = grid.points[y][x]!
                    if tileFlags[thisTile] == nil && thisTile.position == thisTile.homePosition
                    {
                        tileFlags[thisTile] = "complete"
                    }
                }
                x += 1
                if(x >= grid.gridSize.width)
                {
                    x = 0
                    y += 1
                }
            }
        }
        
        if nextDestination == nil || nextTileHome == nil
        {
            return (nil, nil); // Grid is complete
        }
        
        // Now find the tile that should go in that space
        for i in 0..<grid.gridSize.height
        {
            for j in 0..<grid.gridSize.width
            {
                if grid.points[i][j] != nil
                {
                    var thisTile = grid.points[i][j]!
                    if thisTile.homePosition == nextTileHome!
                    {
                        tileFlags[thisTile] = "tileToMove"
                        return (nextDestination, thisTile)
                    }
                }
            }
        }
        
        // Couldn't find tile for destination, so grid must be complete
        return (nil, nil);
    }
    
}

struct AIMovePlan
{
    var tile:Tile
    var dest:GridPoint
    
    init(tile:Tile, dest:GridPoint)
    {
        self.tile = tile
        self.dest = dest
    }
}

// Queue for moves in AI's plan. Simplified linked list.
struct AIMoveQueue
{
    fileprivate var head: Node?
    private var tail: Node?
    private var length = 0
    
    public mutating func addToQueue(point: GridPoint)
    {
        print("Adding to AIMoveQueue: x:",point.x," y:",point.y)
        let newNode = Node(value: point)
        
        if let tailNode = tail // Unwrap tail into tailNode if tail actually contains a Node object (rather than 'nil')
        {
            newNode.previous = tailNode
            tailNode.next = newNode
        }
        else
        {
            head = newNode // No tail, so this must be the only item in the queue
        }
        
        tail = newNode
        
        length += 1
    }
    
    public mutating func getNext() -> GridPoint?
    {
        guard !self.isEmpty, let element = head else { return nil }
        
        let next = element.next
        
        head = next
        next?.previous = nil
        
        if next == nil {
            tail = nil
        }
        
        element.previous = nil
        element.next = nil
        
        length -= 1
        
        return element.value
    }
    
    public var count: Int
    {
        return length
    }
    
    public var isEmpty: Bool
    {
        return head == nil
    }
    
    class Node
    {
        var value: GridPoint
        var next: Node?
        weak var previous: Node? // Weak to avoid circular ownership references
        
        init(value: GridPoint)
        {
            self.value = value
        }
    }
}
