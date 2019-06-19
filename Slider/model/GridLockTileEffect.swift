//
//  GridLockTileEffect.swift
//  Slider
//
//  Created by James Sanford on 19/06/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

public class GridLockTileEffect: TileEffect
{
    var timer:Timer?
    var opponentGrid:SliderGrid?
    
    override func tileDidMove()
    {
        if tile.position == tile.homePosition
        {
            // Find the equivalent of this tile in the other (or the next) grid
            opponentGrid = tile.grid.game.getOpponentGridFor(grid: tile.grid)
            if let opponentGrid = opponentGrid
            {
                opponentGrid.locked = true
                timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.unlockGrid), userInfo: nil, repeats: false)
            }
            
            // Remove the tile effect
            tile.viewController?.removeTileEffect(effect:self)
        }
    }
    
    @objc func unlockGrid()
    {
        if let opponentGrid = opponentGrid
        {
            opponentGrid.locked = false
        }
    }
}

