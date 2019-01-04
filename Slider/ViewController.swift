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
    
    var grid: SliderGrid!
    var gridController: GridViewController!
    var otherGrid: SliderGrid!
    var otherGridController: GridViewController!
    var aiPlayer: AIGridSolver!
    let tileSize = 60.0
  
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create main grid objects
        let gridSize = GridSize(width: 5, height: 5)
        self.grid = SliderGrid(size: gridSize)
        self.gridController = GridViewController(grid: grid, view:sliderGrid)

        // Scramble grid
        grid.scramble(moves:1000)

        // Create second grid
        self.otherGrid = SliderGrid(originalGrid: self.grid)
        self.otherGridController = GridViewController(grid: otherGrid, view:secondSliderGrid)

        // Create views
        self.gridController.createView()
        self.otherGridController.createView()
        
        // Add AI player
        self.aiPlayer = AIGridSolver(gridController: self.otherGridController)
    }

    @IBAction func didSwipeRight(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:self.grid.space.x - 1, y: self.grid.space.y))
    }
    
    @IBAction func didSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:self.grid.space.x + 1, y: self.grid.space.y))
    }
    
    @IBAction func didSwipeUp(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:self.grid.space.x, y: self.grid.space.y + 1))
    }
    
    @IBAction func didSwipeDown(_ sender: UISwipeGestureRecognizer) {
        gridController.moveTile(from:GridPoint(x:self.grid.space.x, y: self.grid.space.y - 1))
    }
}




