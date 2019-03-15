//
//  GridViewConroller.swift
//  Slider
//
//  Created by James Sanford on 04/01/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class GridViewController
{
    var grid:SliderGrid
    var view:UIView
    var tileSize = CGSize(width: 60.0, height: 60.0)
    var gridViewMap = [String:TileViewController]()
    var player: AVAudioPlayer?
    var image: UIImage?
    
    init(grid:SliderGrid, view:UIView)
    {
        self.grid = grid
        self.view = view
        
        grid.viewController = self
        
        self.image = UIImage(named:"stock-pot-sq")!

        do
        {
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error
        {
            print(error.localizedDescription)
        }
    }
    
    func createView()
    {
        // First remove any previously existing tiles from the grid view
        for thisView in view.subviews
        {
            thisView.removeFromSuperview()
        }
        
        tileSize.width = view.frame.size.width / CGFloat(grid.gridSize.width)
        tileSize.height = view.frame.size.width / CGFloat(grid.gridSize.height)
        
        for i in 0..<grid.gridSize.height
        {
            for j in 0..<grid.gridSize.width
            {
                if(grid.points[i][j] != nil)
                {
                    let tileView = createTileViewAt(point: GridPoint(x:j, y:i))
                }
            }
        }
        
    }
    
    func createTileViewAt(point:GridPoint) -> UIView
    {
        // Create new Tile View Controller
        let tile = grid.getTileAt(point: point)!
        let tileViewController = TileViewController(tile:tile)
        gridViewMap[tile.getIdentifier()] = tileViewController

        // Create new View
        let tileView = tileViewController.createView(size: tileSize, image: self.image!)

        view.addSubview(tileView)
        
        return tileView
    }
    
    func moveTile(from: GridPoint) -> Bool
    {
        print("Move tile from x:",from.x," y:",from.y)
        
        // Check 'from point' is within bounds
        if(from.x < 0 || from.y < 0 || from.x >= grid.gridSize.width || from.y >= grid.gridSize.height) { return false }
        
        let tile = grid.points[from.y][from.x]
        let space = grid.space
        let homeCounterBeforeMove = grid.tilesInHomePosition
        if(grid.moveTile(from: from))
        {
            // Move corresponding view
            let dx = CGFloat(space.x - from.x) * tileSize.width
            let dy = CGFloat(space.y - from.y) * tileSize.height
            let tileView = gridViewMap[tile!.getIdentifier()]!.view!
            UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue: 7), animations:
                {
                    tileView.frame.origin.x+=dx
                    tileView.frame.origin.y+=dy
            },completion: { _ in self.checkTileInHomePosition(tile:tile!) } )
        }
        else
        {
            return false
        }
        
        // Check whether tile has moved into or out of original position
        print("count before:",homeCounterBeforeMove," count after:",grid.tilesInHomePosition)
        
        return true
    }
    
    func checkTileInHomePosition(tile:Tile)
    {
        if(tile.position == tile.homePosition)
        {
            // Tile was moved into position
            gridViewMap[tile.getIdentifier()]?.highlightTile()
            
            var soundName = "boop"
            if(grid.tilesInHomePosition == grid.gridSize.width * grid.gridSize.height - 1)
            {
                soundName = "complete"
            }
            guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else { print("couldn't find audio file"); return }
            do
            {
                //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
                
                guard let player = player else { return }
                
                player.play()
                
            }
            catch let error
            {
                print(error.localizedDescription)
            }
        }

    }
    
    func spaceSwappedWithTile(oldTile:Tile, newTile:Tile)
    {
        gridViewMap[oldTile.getIdentifier()]?.view?.removeFromSuperview()
        createTileViewAt(point: newTile.position)
    }
}

