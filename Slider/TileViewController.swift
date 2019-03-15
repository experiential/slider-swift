//
//  TileViewController.swift
//  Slider
//
//  Created by James Sanford on 11/02/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation
import UIKit

class TileViewController
{
    var tile:Tile
    var view:UIImageView?
    var highlightView:UIView?
    var tileEffectView:UIImageView?

    init(tile:Tile)
    {
        self.tile = tile
        tile.viewController = self
    }
    
    func createView(size:CGSize, image:UIImage) -> UIView
    {
        // Create new View
        self.view = UIImageView(frame: CGRect(origin:CGPoint(x: CGFloat(tile.position.x)*size.width, y: CGFloat(tile.position.y)*size.height), size:size))
        
        let contentFrame = CGRect(x: Double(tile.homePosition.x) / Double(tile.grid.gridSize.width), y: Double(tile.homePosition.y) / Double(tile.grid.gridSize.height), width: 1.0 / Double(tile.grid.gridSize.width), height: 1.0 / Double(tile.grid.gridSize.height))
        self.view!.layer.contentsRect = contentFrame
        self.view!.image = image
        
        highlightView = UIView(frame: CGRect(x: 0, y: 0, width: view!.frame.size.width, height: view!.frame.size.height))
        highlightView!.backgroundColor = UIColor.yellow
        highlightView!.layer.opacity = 0.0
        self.view!.addSubview(highlightView!)
        
        return self.view!
    }
    
    func highlightTile()
    {
        if let view = self.view
        {
            view.layer.shadowColor = UIColor.yellow.cgColor
            view.layer.shadowRadius = 30.0
            //view!.layer.shadowOpacity = 1.0
            view.layer.shadowOffset = CGSize.zero
            view.layer.masksToBounds = false
            
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            //animation.beginTime = CACurrentMediaTime() + 0.5;
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = 1.0
            view.layer.add(animation, forKey: animation.keyPath)
            view.layer.shadowOpacity = 0.0
            
            let overlayAnimation = CABasicAnimation(keyPath: "opacity")
            //animation.beginTime = CACurrentMediaTime() + 0.5;
            overlayAnimation.fromValue = 1.0
            overlayAnimation.toValue = 0.0
            overlayAnimation.duration = 0.4
            highlightView?.layer.add(overlayAnimation, forKey: animation.keyPath)
            highlightView?.layer.opacity = 0.0
        }
    }
    
    func addTileEffect(effect:TileEffect)
    {
        // Add tile effect object to tile
        tile.tileEffect = effect
        
        // Add tile effect image to tile view
        // First get shortest dimension of tile view, divide by 3 for width of tile effect
        var width = view!.frame.size.width
        if view!.frame.size.height < width { width = view!.frame.size.height }
        width = width / 2.5
        
        // Now create the tile effect view
        self.tileEffectView = UIImageView(frame: CGRect(origin:CGPoint(x: (view!.frame.size.width - width)/2.0, y: (view!.frame.size.height - width)/2.0), size:CGSize(width: width, height: width)))
        self.tileEffectView!.image = UIImage(named: "tile-effect")
        self.view!.addSubview(self.tileEffectView!)
    }
    
    func removeTileEffect(effect:TileEffect)
    {
        self.tileEffectView?.removeFromSuperview()
        tile.tileEffect = nil
    }
}
