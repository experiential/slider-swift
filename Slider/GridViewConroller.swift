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
    var gridViewMap = [String:UIImageView]()
    var player: AVAudioPlayer?
    
    init(grid:SliderGrid, view:UIView)
    {
        self.grid = grid
        self.view = view
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
                    // Create new View
                    let tileView = UIImageView(frame: CGRect(origin:CGPoint(x: CGFloat(j)*tileSize.width, y: CGFloat(i)*tileSize.height), size:tileSize))
                    
                    tileView.backgroundColor = UIColor.yellow
                    
                    let tile = grid.points[i][j]!
                    gridViewMap[tile.getIdentifier()] = tileView
                    
                    let contentFrame = CGRect(x: Double(tile.homePosition.x) / Double(grid.gridSize.width), y: Double(tile.homePosition.y) / Double(grid.gridSize.height), width: 1.0 / Double(grid.gridSize.width), height: 1.0 / Double(grid.gridSize.height))
                    tileView.layer.contentsRect = contentFrame
                    tileView.image = UIImage(named:"stock-pot-sq")!
                    
                    view.addSubview(tileView)
                }
            }
        }
        
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
            let tileView = gridViewMap[tile!.getIdentifier()]
            UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue: 7), animations:
                {
                    tileView!.frame.origin.x+=dx
                    tileView!.frame.origin.y+=dy
            },completion: nil)
        }
        else
        {
            return false
        }
        
        // Check whether tile has moved into or out of original position
        print("count before:",homeCounterBeforeMove," count after:",grid.tilesInHomePosition)
        if(homeCounterBeforeMove != grid.tilesInHomePosition)
        {
            if(homeCounterBeforeMove < grid.tilesInHomePosition)
            {
                // Tile was moved into position
                let tileView = gridViewMap[tile!.getIdentifier()]
                tileView!.layer.shadowColor = UIColor.yellow.cgColor
                tileView!.layer.shadowRadius = 30.0
                //tileView!.layer.shadowOpacity = 1.0
                tileView!.layer.shadowOffset = CGSize.zero
                tileView!.layer.masksToBounds = false
                
                let animation = CABasicAnimation(keyPath: "shadowOpacity")
                //animation.beginTime = CACurrentMediaTime() + 0.5;
                animation.fromValue = 1.0
                animation.toValue = 0.0
                animation.duration = 1.0
                tileView!.layer.add(animation, forKey: animation.keyPath)
                tileView!.layer.shadowOpacity = 0.0
                
                let overlay: UIView = UIView(frame: CGRect(x: 0, y: 0, width: tileView!.frame.size.width, height: tileView!.frame.size.height))
                overlay.backgroundColor = UIColor.yellow
                tileView!.addSubview(overlay)

                let overlayAnimation = CABasicAnimation(keyPath: "opacity")
                //animation.beginTime = CACurrentMediaTime() + 0.5;
                overlayAnimation.fromValue = 1.0
                overlayAnimation.toValue = 0.0
                overlayAnimation.duration = 0.4
                overlay.layer.add(overlayAnimation, forKey: animation.keyPath)
                overlay.layer.opacity = 0.0

                var soundName = "boop"
                if(grid.tilesInHomePosition == grid.gridSize.width * grid.gridSize.height - 1)
                {
                    soundName = "complete"
                }
                guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else { print("couldn't find audio file"); return true}
                do {
                    //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                    AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                    player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
                    
                    guard let player = player else { return true }
                    
                    player.play()
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            else
            {
                // Tile was moved out of position
            }
        }
        
        return true
    }
    
    
}

