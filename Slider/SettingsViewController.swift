//
//  SettingsViewController.swift
//  Slider
//
//  Created by James Sanford on 31/01/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var aiLevelField: UITextField!
    @IBOutlet weak var aiLevelStepper: UIStepper!
    @IBOutlet weak var gridWidthField: UITextField!
    @IBOutlet weak var gridWidthStepper: UIStepper!
    @IBOutlet weak var gridHeightField: UITextField!
    @IBOutlet weak var gridHeightStepper: UIStepper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        aiLevelField.text = String(Settings.aiLevel)
        aiLevelStepper.value = Double(Settings.aiLevel)
        gridWidthField.text = String(Settings.gridSize.width)
        gridWidthStepper.value = Double(Settings.gridSize.width)
        gridHeightField.text = String(Settings.gridSize.height)
        gridHeightStepper.value = Double(Settings.gridSize.height)
    }

    @IBAction func aiLevelFieldValueChanged(_ sender: Any)
    {
        aiLevelStepper.value = Double(aiLevelField.text!) ?? Double(Settings.aiLevel)
    }
    
    @IBAction func aiLevelStepperValueChanged(_ sender: Any)
    {
        aiLevelField.text = String(Int(aiLevelStepper.value))
    }
    
    @IBAction func gridWidthFieldValueChanged(_ sender: Any)
    {
        gridWidthStepper.value = Double(gridWidthField.text!) ?? Double(Settings.gridSize.width)
    }
    
    @IBAction func gridWidthStepperValueChanged(_ sender: Any)
    {
        gridWidthField.text = String(Int(gridWidthStepper.value))
    }
    
    @IBAction func gridHeightFieldValueChanged(_ sender: Any)
    {
        gridHeightStepper.value = Double(gridHeightField.text!) ?? Double(Settings.gridSize.height)
    }
    
    @IBAction func gridHeightStepperValueChanged(_ sender: Any)
    {
        gridHeightField.text = String(Int(gridHeightStepper.value))
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        print("FUNC CALL! Prepare called!")
        
        // Update Settings values to store any changes
        Settings.aiLevel = Int(aiLevelStepper.value)
        Settings.gridSize = GridSize(width: Int(gridWidthStepper.value), height: Int(gridHeightStepper.value))
    }

}
