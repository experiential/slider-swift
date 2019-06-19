//
//  Tile.swift
//  Slider
//
//  Created by James Sanford on 19/06/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

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
