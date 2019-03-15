//
//  ViewController.swift
//  Slider
//
//  Created by James Sanford on 14/12/2018.
//  Copyright © 2018 Experiential Services. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    @IBOutlet weak var sliderGrid: UIView!
    @IBOutlet weak var secondSliderGrid: UIView!
    
    var game: Game!
    var gridController: GridViewController!
    var otherGridController: GridViewController!
    var aiPlayer: AIGridSolver!
  
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create main grid objects
        newGame()
    }

    func newGame()
    {
        // Create game object
        self.game = Game(players: 2, size: Settings.gridSize, space: Settings.defaultSpacePosition)
        
        // Create view controllers for each grid
        self.gridController = GridViewController(grid: game.grids[0], view:sliderGrid)
        self.otherGridController = GridViewController(grid: game.grids[1], view:secondSliderGrid)
        
        // Create views
        self.gridController.createView()
        self.otherGridController.createView()
        
        // Add AI player
        if self.aiPlayer != nil
        {
            self.aiPlayer.end()
        }
        self.aiPlayer = AIGridSolver(gridController: self.otherGridController, level: Settings.aiLevel)

        // Testing only! Add TileEffect to top left tile
        if let theTile = game.grids[0].findTileWithHomePosition(point:GridPoint(x:4, y:2))
        {
            theTile.viewController?.addTileEffect(effect:SpaceSwitchTileEffect(tile:theTile))
        }
    }
    
    @IBAction func newButtonPressed(_ sender: Any)
    {
        newGame()
    }
    
    @IBAction func didSwipeRight(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:game.grids[0].space.x - 1, y: game.grids[0].space.y))
    }
    
    @IBAction func didSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:game.grids[0].space.x + 1, y: game.grids[0].space.y))
    }
    
    @IBAction func didSwipeUp(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:game.grids[0].space.x, y: game.grids[0].space.y + 1))
    }
    
    @IBAction func didSwipeDown(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:game.grids[0].space.x, y: game.grids[0].space.y - 1))
    }

    @IBAction func completeSettingsChange(_ segue: UIStoryboardSegue) {
        print("DISMISS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        //self.dismiss(animated: true, completion: nil)
    }

}




