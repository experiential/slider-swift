//
//  Game.swift
//  Slider
//
//  Created by James Sanford on 15/02/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

class Game
{
    var grids: [SliderGrid] = []
    var noOfPlayers = 2
    
    init(players: Int, size: GridSize, space: GridPoint)
    {
        self.noOfPlayers = players
        let grid = SliderGrid(size: size, space: space, game: self)
        self.grids.append(grid)
        
        // Scramble grid
        grid.scramble(moves:size.width * size.height * 1000)

        // Clone grid for each other player
        for gridNumber in 1..<noOfPlayers
        {
            self.grids.append(SliderGrid(originalGrid: grid))
        }
    }
    
    func getOpponentGridFor(grid:SliderGrid) -> SliderGrid?
    {
        // If there is only one player, there can be no opponent grid, so return nil
        if noOfPlayers < 2 { return nil }
        
        if let gridIndex = grids.index(where: {$0 === grid})
        {
            // Currently this app is designed for a max of two players, but just in case, we return the next grid from the array of grids, unless the specified grid is the last one in which case we return the first.
            var opponentGridIndex = gridIndex + 1
            if opponentGridIndex >= noOfPlayers { opponentGridIndex = 0 }
            return grids[opponentGridIndex]
        }
        else
        {
            print("Error: Game.getOpponentGridFor() called with grid not in array of grids for this game!")
            return nil
        }
    }
}
