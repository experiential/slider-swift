//
//  AIMoveQueue.swift
//  Slider
//
//  Created by James Sanford on 19/06/2019.
//  Copyright © 2019 Experiential Services. All rights reserved.
//

import Foundation

// Queue for moves in AI's plan. Simplified linked list.
struct AIMoveQueue
{
    fileprivate var head: Node?
    fileprivate var tail: Node?
    private var length = 0
    
    public mutating func addToQueue(point: GridPoint)
    {
        print("Adding to AIMoveQueue: x:",point.x," y:",point.y)
        let newNode = Node(value: point)
        
        if let tailNode = tail // Unwrap tail into tailNode if tail actually contains a Node object (rather than 'nil')
        {
            newNode.previous = tailNode
            tailNode.next = newNode
        }
        else
        {
            head = newNode // No tail, so this must be the only item in the queue
        }
        
        tail = newNode
        
        length += 1
    }
    
    public mutating func getNext() -> GridPoint?
    {
        guard !self.isEmpty, let element = head else { return nil }
        
        let next = element.next
        
        head = next
        next?.previous = nil
        
        if next == nil {
            tail = nil
        }
        
        element.previous = nil
        element.next = nil
        
        length -= 1
        
        return element.value
    }
    
    public var last: GridPoint?
    {
        return tail?.value
    }
    
    public var count: Int
    {
        return length
    }
    
    public var isEmpty: Bool
    {
        return head == nil
    }
    
    public mutating func clearQueue()
    {
        head = nil
        tail = nil
        length = 0
    }
    
    class Node
    {
        var value: GridPoint
        var next: Node?
        weak var previous: Node? // Weak to avoid circular ownership references
        
        init(value: GridPoint)
        {
            self.value = value
        }
    }
}
