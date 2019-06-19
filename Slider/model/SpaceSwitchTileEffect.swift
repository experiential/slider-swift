//
//  SpaceSwitchTileEffect.swift
//  Slider
//
//  Created by James Sanford on 19/06/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

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

