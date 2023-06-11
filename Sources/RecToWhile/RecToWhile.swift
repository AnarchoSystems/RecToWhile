//
//  RecToWhile.swift
//  
//
//  Created by Markus Kasperczyk on 24.01.23.
//

public enum Continuation<Routine : Algorithm> {
    
    case `continue`
    case call(Routine, (inout Routine, inout Routine.SharedData, Routine.Output) -> Void)
    case result(Routine.Output)
    
    static func call(_ routine: Routine, _ then: @escaping (inout Routine, Routine.Output) -> Void) -> Self {
        .call(routine) {this, _, result in then(&this, result)}
    }
}

public protocol Algorithm<Input, SharedData, Output> {
    
    associatedtype Input
    associatedtype Output
    associatedtype SharedData
    static func initialize(_ input: Input) -> (Self, SharedData)
    mutating func step(_ shared: inout SharedData) -> Continuation<Self>
    
}

public extension Algorithm {
    
    static func run(_ input: Input, stackSize: Int = 1024) -> Output {
        
        var (this, sharedData) = initialize(input)
        
        var stack = [(Self, ((inout Self, inout SharedData, Output) -> Void)?)]()
        
        // just in case that there are a bunch of subroutine calls...
        stack.reserveCapacity(stackSize)
        
        stack.append((this, nil))
        
        while true {
            switch stack[stack.count - 1].0.step(&sharedData) {
            case .continue:
                continue
            case .call(let subRoutine, let then):
                stack[stack.count - 1].1 = then
                stack.append((subRoutine, nil))
            case .result(let subResult):
                stack.removeLast()
                guard let onReturn = stack.last?.1 else {
                    return subResult
                }
                onReturn(&stack[stack.count - 1].0, &sharedData, subResult)
            }
        }
        
    }
    
}


public enum SteppingContinuation<Algo, Data> {
    case call(Algo)
    case manip((inout Data) -> Void)
}

public protocol SteppingAlgo {
    associatedtype Input
    associatedtype Data
    static func initialize(_ input: Input) -> (Self, Data)
    var steps : [SteppingContinuation<Self, Data>] {get}
}

public extension SteppingAlgo {
    typealias Algorithm = Stepper<Self>
}

public struct Stepper<Algo : SteppingAlgo> : Algorithm {
    
    public typealias Output = Algo.Data
    public typealias SharedData = Algo.Data
    
    let algo : Algo
    var stepIdx = 0
    
    public static func initialize(_ input: Algo.Input) -> (Stepper<Algo>, Algo.Data) {
        let (algo, data) = Algo.initialize(input)
        return (.init(algo: algo), data)
    }
    
    var currentStep : SteppingContinuation<Algo, Algo.Data>? {
        algo.steps.indices.contains(stepIdx) ? algo.steps[stepIdx] : nil
    }
    
    public mutating func step(_ shared: inout Algo.Data) -> Continuation<Stepper<Algo>> {
        guard let currentStep else {
            return .result(shared)
        }
        switch currentStep {
        case .call(let push):
            return .call(.init(algo: push)) {this, _ in
                this.stepIdx += 1
            }
        case .manip(let manip):
            stepIdx += 1
            manip(&shared)
            return .continue
        }
    }
    
}
