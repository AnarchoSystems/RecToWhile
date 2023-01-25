//
//  RecToWhile.swift
//  
//
//  Created by Markus Kasperczyk on 24.01.23.
//

public enum Continuation<Routine, Return> {
    case expand(Routine)
    case call(Routine)
    case result(Return)
}

public protocol Algorithm {
    
    associatedtype Output
    var continuation : Continuation<Self, Output> {get}
    mutating func onReturn(_ subResult: Output)
    
}

public extension Algorithm {
    
    func run() -> Output {
        
        var stack = [Self]()
        
        // just in case that there are a bunch of subroutine calls...
        stack.reserveCapacity(1024)
        
        stack.append(self)
        
        while true {
            switch stack[stack.count - 1].continuation {
            case .expand(let expansion):
                stack[stack.count - 1] = expansion
            case .call(let subRoutine):
                stack.append(subRoutine)
            case .result(let subResult):
                stack.removeLast()
                if stack.isEmpty {
                    return subResult
                }
                stack[stack.count - 1].onReturn(subResult)
            }
        }
        
    }
    
}
