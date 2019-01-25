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
    var gridIsComplete = false
    
    
    init(gridController:GridViewController)
    {
        self.gridController = gridController
        self.grid = gridController.grid
        
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.makeAMove), userInfo: nil, repeats: true)
    }
    
    @objc func makeAMove()
    {
        if plan.isEmpty && !gridIsComplete
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
            
            // Set flag on 'object tile' (the one to be moved) so that we don't move it while bring the space into position
            tileFlags[nextTile!] = "object"
            
            // Check direction we want the tile to go in
            let pos = nextTile!.position
            let dest = nextDest!
            var spaceDest = pos
            
            let dx = dest.x - pos.x
            let dy = dest.y - pos.y
            
            if(abs(dx) > abs(dy) || dy == 0) { spaceDest.x += Int(dx/abs(dx)) }
            else { spaceDest.y += Int(dy/abs(dy)) }
            
            // Check space destination point for whether it has a complete tile
            var tileAtDest = grid.getTileAt(point: spaceDest)
            if let tileAtDest = tileAtDest
            {
                if tileFlags[tileAtDest] == "complete"
                {
                    spaceDest = pos
                    if(abs(dx) > abs(dy)) { spaceDest.y += Int(dy/abs(dy)) }
                    else { spaceDest.x += Int(dx/abs(dx)) }
                }
            }
            
            print("Space destination: x:",spaceDest.x," y:",spaceDest.y)
            
            if(grid.space != spaceDest)
            {
                // Move space to destination point
                var space = grid.space
                var previousSpace = space
                while(space != spaceDest && plan.count < (grid.gridSize.width + grid.gridSize.height + 2))
                {
                    // Create list of possible moves
                    var possiblePoints = [ "up":space, "down":space, "left":space, "right":space ]
                    possiblePoints["up"]!.y -= 1
                    possiblePoints["down"]!.y += 1
                    possiblePoints["left"]!.x -= 1
                    possiblePoints["right"]!.x += 1
                    var availablePoints = possiblePoints
                    // Remove moves that go outside the grid and that move flagged tiles (e.g. complete ones)
                    availablePoints = availablePoints.filter
                    {
                        // First check whether the move is out of bounds
                        if grid.gridPointIsOutOfBounds(point: $0.value) { return false }
                        // Now check whether the move would be reversing the previous move, if there is one
                        if previousSpace == $0.value { return false }
                        var tile = grid.getTileAt(point: $0.value)
                        if let tile = tile
                        {
                            return tileFlags[tile] == nil
                        }
                        else
                        {
                            return true; // Point contains the space, so that's ok to move through
                        }
                    }

                    var tileToMove:Tile? = nil
                    var newSpace = space
                    while newSpace == space
                    {
                        // Determine which direction we're going in, and whether the x distance is greater than the y
                        let dx = spaceDest.x - space.x
                        let dy = spaceDest.y - space.y
                        
                        var direction = ""
                        if abs(dx) > abs(dy)
                        {
                            if dx > 0 { direction = "right"; newSpace.x += 1 }
                            else { direction = "left"; newSpace.x -= 1 } // dx must be < 0 (dx can't be 0)
                            //newSpace.x += Int(dx/abs(dx))
                        }
                        else
                        {
                            if dy > 0 { direction = "down"; newSpace.y += 1 }
                            else { direction = "up"; newSpace.y -= 1 } // dy must be < 0 (dy can't be 0)
                            //newSpace.y += Int(dy/abs(dy))
                        }

                        if availablePoints[direction] == nil
                        {
                            // Either boundary was reached, or we must not move this tile, so must go around
                            if abs(dx) > abs(dy)
                            {
                                newSpace = space
                                
                                // Trying to move left/right, so check whether up or down is preferred (or space is at top/bottom of grid)
                                if (dy >= 0 || availablePoints["up"] == nil) && availablePoints["down"] != nil
                                {
                                    newSpace.y += 1
                                }
                                else if availablePoints["up"] != nil // Divert up
                                {
                                    newSpace.y -= 1
                                }
                                else // Only option is backwards
                                {
                                    newSpace.x -= Int(dx/abs(dx)) // Need bounds check here
                                }
                            }
                            else
                            {
                                newSpace = space
                                
                                // Trying to move up/down, so check whether left or right is preferred (or space is at far left/right of grid)
                                if (dx >= 0 || availablePoints["left"] == nil) && availablePoints["right"] != nil // >= because if dx is zero, we usually want to divert to the right
                                {
                                    newSpace.x += 1
                                }
                                else
                                {
                                    // We are (probably) caught in a corner here, so need to determine the correct way to try to go around, which means staying close to the object tile
                                    var objectTileIsRight = false
                                    if let rightTile = grid.getTileAt(point: possiblePoints["right"]!)
                                    {
                                        if tileFlags[rightTile] == "object"
                                        {
                                            objectTileIsRight = true
                                        }
                                    }
                                    
                                    if availablePoints["left"] != nil && !objectTileIsRight // Divert to left
                                    {
                                        newSpace.x -= 1
                                    }
                                    else
                                    {
                                        newSpace.y -= Int(dy/abs(dy)) // Need bounds check here
                                    }
                                }
                            }
                        }
                        
                        tileToMove = grid.getTileAt(point: newSpace)
                    }
                    
                    if tileToMove != nil && tileFlags[tileToMove!] != nil
                    {
                        print("PLAN: Ran out of possible moves!")
                        
                        // Must have run out of possible moves
                        newSpace = availablePoints.values.first!
                    }
                    
                    previousSpace = space
                    space = newSpace
                    plan.addToQueue(point: space)
                }
                
            }
            
            // Unset 'object' flag on object tile
            tileFlags[nextTile!] = nil

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
        var start = GridPoint(x:0, y:0)

        // Determine from where to start checking for rows and columns
        // If x coordinate of the original location of the space is less than the
        // 'middle' on the x-axis, then start from the right, not the left (max x)
        if Float(grid.originalSpace.x) < Float(grid.gridSize.width - 1) / 2.0
        {
            start.x = grid.gridSize.width - 1
        }
        // Similarly for y
        if Float(grid.originalSpace.y) < Float(grid.gridSize.height - 1) / 2.0
        {
            start.y = grid.gridSize.height - 1
        }
        
        // Check columns and rows in order (in towards the final space position) until we
        // find one that isn't complete
        var columnX = start.x
        var columnXDirection = (start.x > 0) ? -1 : 1
        var columnsChecked:[Int] = []
        var rowY = start.y
        var rowYDirection = (start.y > 0) ? -1 : 1
        var rowsChecked:[Int] = []
        while(nextDestination == nil && (columnsChecked.count < grid.gridSize.height || rowsChecked.count < grid.gridSize.width))
        {
            // Decide whether to check row or column for completeness next
            var mode = "row"
            if grid.gridSize.height - columnsChecked.count > grid.gridSize.width - rowsChecked.count // Check whether more rows are left to complete, or more columns
            {
                mode = "column"
            }

            // Make a list of the locations in this row/column so we don't have to keep
            // doing it again and again.
            var line:[GridPoint] = []
            var max = 0
            var point = GridPoint(x:0, y:0)
            if mode == "row"
            {
                max = grid.gridSize.width
                point.y = rowY
                print("PLAN: Checking ",mode," at y=",rowY)
            }
            else
            {
                max = grid.gridSize.height
                point.x = columnX
                print("PLAN: Checking ",mode," at x=",columnX)
            }
            for i in 0..<max
            {
                if mode == "row" { point.x = i }
                else {point.y = i }
                line.append(point)
            }

            // Check each tile in row/column for whether it's in its home position
            var pointsNotComplete:[GridPoint] = []
            for thisPoint in line
            {
                let thisTile = grid.getTileAt(point: thisPoint)
                var tileInHomePosition = false
                if let thisTile = thisTile
                {
                    if thisTile.position == thisTile.homePosition
                    {
                        tileInHomePosition = true
                    }
                }
                else
                {
                    // This is the space, so check whether it's in the final space position
                    if thisPoint == grid.originalSpace
                    {
                        tileInHomePosition = true
                    }
                }
                
                if !tileInHomePosition
                {
                    // Note this location
                    pointsNotComplete.append(thisPoint)
                    print("PLAN: Tile at ",thisPoint," is not in final position")
                }
            }
            
            // Line (row/column) has now been checked, so see whether there are any tiles missing
            // in this line
            if pointsNotComplete.count == 0
            {
                // All tiles complete, so mark these tiles as 'not to be touched' and move on
                print("PLAN: All tiles in final position, marking as complete")
                for point in line
                {
                    let thisTile = grid.getTileAt(point: point)
                    if thisTile != nil
                    {
                        tileFlags[thisTile!] = "complete"
                    }
                }
                
                // Add row/column to 'rows/columns checked' list, and move on to next row/column
                // TODO: add code here(? or when initally check the new row/column?) to search from other side of grid if space originally in/near the new row/column
                if mode == "row"
                {
                    rowsChecked.append(rowY)
                    rowY += rowYDirection
                }
                else
                {
                    columnsChecked.append(columnX)
                    columnX += columnXDirection
                }
                
                continue
            }
            else
            {
                // Check whether we're down to the last one or two tiles not in position and whether they're adjacent (if there are two), or if there is only one, that the space is in the last place, and the last tile to go in the line is next to the space... i.e. we are carrying out the 'end of row move'
                var endOfLine = false
                if pointsNotComplete.count == 1 && grid.getTileAt(point: pointsNotComplete[0]) == nil
                {
                    // Check whether the last remaining tile is next to the space
                    var lastTile = grid.findTileWithHomePosition(point: pointsNotComplete[0])
                    if let lastTile = lastTile
                    {
                        if lastTile.position.isAdjacentTo(point: pointsNotComplete[0])
                        {
                            endOfLine = true
                        }
                    }
                }
                else if pointsNotComplete.count == 2 && pointsNotComplete[0].isAdjacentTo(point:pointsNotComplete[1])
                {
                    // Last two points to fill are adjacent, so either we start, or continue, the 'end of row move'
                    endOfLine = true
                }
                
                if pointsNotComplete.count > 2
                {
                    print("PLAN: More than two tiles out of position")

                    // Mark first incomplete location and tile that goes there as next destination and the tile to move there
                    nextDestination = pointsNotComplete[0]
                    nextTileHome = pointsNotComplete[0]

                    // Mark complete tiles as complete
                    for point in line
                    {
                        let tile = grid.getTileAt(point: point)
                        if tile != nil && tile!.position == tile!.homePosition
                        {
                            tileFlags[tile!] = "complete"
                        }
                        else
                        {
                            break
                        }
                    }
                }
                else if pointsNotComplete.count <= 2 && !endOfLine
                {
                    // Only two tiles out of position but they're not adjacent
                    if pointsNotComplete.count == 2 { print("PLAN: Only two tiles out of position but they're not adjacent") }
                    else { print("PLAN: Only one tile out of position but can't complete the line") }

                    // Mark first incomplete location and tile that goes there as next destination and the tile to move there
                    nextDestination = pointsNotComplete[0]
                    
                    // Find where the next destination is in the list and identify a tile next to it
                    var completedPointToUnlock:GridPoint? = nil
                    var endOfLine = false
                    if let indexAndPoint = line.enumerated().first(where: {$0.element == nextDestination})
                    {
                        // If it's the last tile in the line, 'unlock' (allow to be moved) the tile before it, otherwise unlock the tile after it.
                        if indexAndPoint.offset == line.count - 1
                        {
                            completedPointToUnlock = line[indexAndPoint.offset - 1]
                            endOfLine = true
                        }
                        else
                        {
                            completedPointToUnlock = line[indexAndPoint.offset + 1]
                        }
                        print("PLAN: Choosing adjacent tile at ",completedPointToUnlock,"to unlock")
                    }
                    
                    // If only one point in the line is not complete (and we've checked that we're not in position for the 'end of line manoeuvre') then a tile that's in position, and that's next to the incomplete point, needs to be moved to the incomplete point for the end of line move. Otherwise two points are incomplete, so we just want to move the tile for point 0 to point 1 (to prepare for the end of line move)
                    if pointsNotComplete.count == 1
                    {
                        if endOfLine
                        {
                            nextTileHome = completedPointToUnlock
                        }
                        else
                        {
                            nextDestination = completedPointToUnlock
                            nextTileHome = pointsNotComplete[0]
                        }
                    }
                    else
                    {
                        nextTileHome = pointsNotComplete[0]
                    }

                    // Mark complete tiles as complete, except for one next to the next destination (unset that one as complete)
                    for point in line
                    {
                        let tile = grid.getTileAt(point: point)
                        if tile != nil
                        {
                            if tile!.position == tile!.homePosition && point != completedPointToUnlock!
                            {
                                tileFlags[tile!] = "complete"
                            }
                            else if point == completedPointToUnlock!
                            {
                                tileFlags[tile!] = nil
                            }
                        }
                    }
                    
                }
                else
                {
                    // Start or continue 'end of line' manoeuvre
                    print("PLAN: Start or continue 'end of line' manoeuvre")
                    
                    if pointsNotComplete.count == 2
                    {
                        var tile0 = grid.getTileAt(point: pointsNotComplete[0])
                        var tile1 = grid.getTileAt(point: pointsNotComplete[1])
                        
                        if tile1 == nil || tile1!.homePosition != pointsNotComplete[0]
                        {
                            print("PLAN: Get first tile into second spot")

                            // Get tile for point 0 into point 1
                            nextDestination = pointsNotComplete[1]
                            nextTileHome = pointsNotComplete[0]
                            
                            // Mark tiles not in point 0 or 1 as complete
                            for point in line
                            {
                                if point != pointsNotComplete[0] && point != pointsNotComplete[1]
                                {
                                    let thisTile = grid.getTileAt(point: point)
                                    if thisTile != nil
                                    {
                                        tileFlags[thisTile!] = "complete"
                                    }
                                }
                            }
                        }
                        else
                        {
                            // Tile for point 0 is in position in point 1, but now we need to check for the 'entangled' position where the tile for point 1 is (or will be shortly) in point 0, which makes it impossible to get the last two tiles into the line in the correct order.
                            var entangled = false
                            if tile0 != nil && tile0!.homePosition == pointsNotComplete[1] { entangled = true }
                            else if tile0 == nil
                            {
                                let finalTile = grid.findTileWithHomePosition(point: pointsNotComplete[1])
                                if let finalTile = finalTile
                                {
                                    if finalTile.position.isAdjacentTo(point: pointsNotComplete[0])
                                    {
                                        entangled = true
                                    }
                                }
                            }

                            if entangled
                            {
                                print("PLAN: Entangled!!!!!!!! Get final tile out of the way")

                                var outOfTheWayPoint = pointsNotComplete[0]
                                if mode == "row" { outOfTheWayPoint.y += 2} // below the row
                                else { outOfTheWayPoint.x += 2 } // to the right of the column
                                
                                nextDestination = outOfTheWayPoint
                                nextTileHome = pointsNotComplete[1]
                                
                                // Mark tiles not in point 0 or 1 as complete
                                for point in line
                                {
                                    let thisTile = grid.getTileAt(point: point)
                                    if thisTile != nil
                                    {
                                        if point != pointsNotComplete[0] && point != pointsNotComplete[1]
                                        {
                                            tileFlags[thisTile!] = "complete"
                                        }
                                        else
                                        {
                                            tileFlags[thisTile!] = nil
                                        }
                                    }
                                }
                            }
                            else
                            {
                                // Tile for point 0 is in position in point 1, so get tile for point 1 next to point 1, closer to the final space position
                                // TODO: This is a fudge, we just go down or right, rather than towards the 'final space position'... fix later!
                                var adjacentPoint = pointsNotComplete[1]
                                if mode == "row" { adjacentPoint.y += 1} // below the row
                                else { adjacentPoint.x += 1 } // to the right of the column
                                
                                var adjacentTile = grid.getTileAt(point: adjacentPoint)
                                if adjacentTile == nil || adjacentTile!.homePosition != pointsNotComplete[1]
                                {
                                    print("PLAN: Get second tile into 'adjacent' spot")

                                    // Adjacent point doesn't contain the tile for point 1, so get it there
                                    nextDestination = adjacentPoint
                                    nextTileHome = pointsNotComplete[1]
                                    
                                    // Mark tiles not in point 0 or 1 as complete
                                    for point in line
                                    {
                                        let thisTile = grid.getTileAt(point: point)
                                        if thisTile != nil
                                        {
                                            if point != pointsNotComplete[0] && point != pointsNotComplete[1]
                                            {
                                                tileFlags[thisTile!] = "complete"
                                            }
                                            else if point == pointsNotComplete[1]
                                            {
                                                tileFlags[thisTile!] = "hold"
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    print("PLAN: Both tiles in position, so get first tile into home spot")

                                    // Both tiles are in position, so move first tile into point 0
                                    nextDestination = pointsNotComplete[0]
                                    nextTileHome = pointsNotComplete[0]
                                    
                                    // Mark tiles not in point 0 or 1 as complete, the two 'end' tiles as 'hold'
                                    tileFlags[adjacentTile!] = "hold"
                                    for point in line
                                    {
                                        let thisTile = grid.getTileAt(point: point)
                                        if thisTile != nil
                                        {
                                            if point != pointsNotComplete[0] && point != pointsNotComplete[1]
                                            {
                                                tileFlags[thisTile!] = "complete"
                                            }
                                            else if point == pointsNotComplete[1]
                                            {
                                                tileFlags[thisTile!] = "hold"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else // Only one point not complete in this line
                    {
                        print("PLAN: Final move! Get final tile into home spot")

                        // Final move for end of line! Move final tile into space
                        nextDestination = pointsNotComplete[0]
                        nextTileHome = pointsNotComplete[0]

                        // Mark tiles not in point 0 as complete, the 'end' tile as 'hold'
                        let finalTile = grid.findTileWithHomePosition(point: pointsNotComplete[0])
                        if let finalTile = finalTile
                        {
                            tileFlags[finalTile] = "hold"
                        }

                        for point in line
                        {
                            let thisTile = grid.getTileAt(point: point)
                            if thisTile != nil
                            {
                                if point != pointsNotComplete[0]
                                {
                                    tileFlags[thisTile!] = "complete"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if nextDestination == nil || nextTileHome == nil
        {
            gridIsComplete = true
            return (nil, nil); // Grid is complete
        }
        
        // Now find the tile that should go in that space
        let tileToMove = grid.findTileWithHomePosition(point: nextTileHome!)
        if let tileToMove = tileToMove
        {
            return (nextDestination, tileToMove)
        }
        
        // Couldn't find tile for destination, so grid must be complete
        gridIsComplete = true
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
    fileprivate var tail: Node?
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
    
    public var last: GridPoint?
    {
        return tail?.value
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
