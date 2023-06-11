import XCTest
@testable import RecToWhile

final class RecToWhileTests: XCTestCase {
    
    func testEvenOdd() {
        
        for idx in 0..<1000 {
            XCTAssertEqual(EvenOdd.run((check: .checkEven, value: numericCast(idx))),
                           idx % 2 == 0)
            XCTAssertEqual(EvenOdd.run((check: .checkOdd, value: numericCast(idx))),
                           idx % 2 == 1)
        }
        
    }
    
    func testHanoi() {
        
        for size in 3...10 {
            do {
                var hanoi = Hanoi(size)
                solveHanoi(&hanoi)
                XCTAssert(hanoi.isSolved, "pile 1: \(hanoi.pile1), pile 2: \(hanoi.pile2), pile3: \(hanoi.pile3)")
                
            }
            
            do {
                let hanoi = SimpleHanoiSolver.Algorithm.run(Hanoi(size))
                XCTAssert(hanoi.isSolved,
                          "pile 1: \(hanoi.pile1), pile 2: \(hanoi.pile2), pile3: \(hanoi.pile3)")
            }
        }
    }
    
    func testAckermann() {
        
        for i in 0...3 {
            for j in 0...13 {
                XCTAssertEqual(ackermannRec(numericCast(i), numericCast(j)),
                               Ackermann.run(.init(n: numericCast(i), m: numericCast(j))))
            }
        }
        
    }
    
    func fib(req: Int) -> (Int, Int) {
        if req <= 1 {return (1, 1)}
        let (nMin1, nMin2) = fib(req: req - 1)
        return (nMin1 + nMin2, nMin1)
    }
    
    func testFib() {
        
        for idx in 0..<50 {
            let res1 = fib(req: idx).0
            let res2 = Fibonacci.run(idx).last!
            XCTAssertEqual(res1, res2)
        }
        
    }
    
}

enum EvenOdd : Algorithm {
    
    typealias Output = Bool
    
    case checkEven
    case checkOdd
    
    mutating func toggle() {
        switch self {
        case .checkEven:
            self = .checkOdd
        case .checkOdd:
            self = .checkEven
        }
    }
    
    static func initialize(_ input: (EvenOdd, UInt)) -> (EvenOdd, UInt) {
        input
    }
    
    mutating func step(_ int: inout UInt) -> Continuation<EvenOdd> {
        if int == 0 {
            return .result(self == .checkEven)
        }
        toggle()
        int -= 1
        return .continue
    }
    
}

struct Hanoi {
    
    private(set) var pile1 : [Int]
    private(set) var pile2 = [Int]()
    private(set) var pile3 = [Int]()
    
    init(_ size: Int) {
        pile1 = Array(0..<size)
    }
    
    enum PileIdx {
        case first
        case second
        case third
    }
    
    private(set) subscript(_ idx: PileIdx) -> [Int] {
        get {
            switch idx {
            case .first:
                return pile1
            case .second:
                return pile2
            case .third:
                return pile3
            }
        }
        set {
            switch idx {
            case .first:
                pile1 = newValue
            case .second:
                pile2 = newValue
            case .third:
                pile3 = newValue
            }
        }
    }
    
    mutating func move(from: PileIdx, to: PileIdx) {
        guard !self[from].isEmpty else {return}
        guard self[to].isEmpty || self[from].last! > self[to].last! else {return}
        let elm = self[from].removeLast()
        self[to].append(elm)
    }
    
    var isSolved : Bool {
        pile1.isEmpty && pile2.isEmpty && pile3 == pile3.sorted()
    }
    
}

func solveHanoi(_ hanoi: inout Hanoi) {
    moveAll(hanoi: &hanoi,
            amount: hanoi.pile1.count,
            from: .first,
            to: .third,
            via: .second)
}

func moveAll(hanoi: inout Hanoi,
             amount: Int,
             from: Hanoi.PileIdx,
             to: Hanoi.PileIdx,
             via: Hanoi.PileIdx) {
    if amount <= 0 {
        return
    }
    moveAll(hanoi: &hanoi, amount: amount - 1, from: from, to: via, via: to)
    hanoi.move(from: from, to: to)
    moveAll(hanoi: &hanoi, amount: amount - 1, from: via, to: to, via: from)
}

struct SimpleHanoiSolver : SteppingAlgo {
    
    let from : Hanoi.PileIdx
    let to : Hanoi.PileIdx
    let via : Hanoi.PileIdx
    let amount : Int
    
    static func initialize(_ input: Hanoi) -> (SimpleHanoiSolver, Hanoi) {
        (.init(from: .first,
               to: .third,
               via: .second,
               amount: input.pile1.count),
         input)
    }
    
    var steps : [SteppingContinuation<Self, Hanoi>] {
        if amount <= 0 {
            return []
        }
        return [
            .call(.init(from: from,
                        to: via,
                        via: to,
                        amount: amount - 1)),
            
                .manip{hanoi in hanoi.move(from: from, to: to)},
            
                .call(.init(from: via,
                            to: to,
                            via: from,
                            amount: amount - 1))
        ]
    }
    
}

func ackermannRec(_ n: UInt, _ m: UInt) -> UInt {
    var lookUp = [IntPair:UInt]()
    return ackermannRec(n, m, lookup: &lookUp)
}

func ackermannRec(_ n: UInt, _ m: UInt, lookup: inout [IntPair : UInt]) -> UInt {
    
    if let memo = lookup[IntPair(n: n, m: m)] {
        return memo
    }
    
    if n == 0 {
        return m+1
    }
    if m == 0 {
        return ackermannRec(n-1, 1, lookup: &lookup)
    }
    let res1 = ackermannRec(n, m-1, lookup: &lookup)
    lookup[IntPair(n: n, m: m-1)] = res1
    let res2 = ackermannRec(n-1, res1, lookup: &lookup)
    lookup[IntPair(n: n-1, m: res1)] = res2
    return res2
    
}

struct IntPair : Hashable {
    let n : UInt
    let m : UInt
}

enum Ackermann : Algorithm, Hashable {
    
    typealias Output = UInt
    
    static func initialize(_ input: IntPair) -> (Ackermann, [Ackermann : UInt]) {
        (.requested(n: input.n, m: .computed(input.m)), [:])
    }
    
    indirect case requested(n: UInt, m: Ackermann)
    case computed(UInt)
    
    mutating func step(_ lookup: inout [Ackermann : UInt]) -> Continuation<Ackermann> {
        if let memo = lookup[self] {
            return .result(memo)
        }
        switch self {
        case .computed(let result):
            return .result(result)
        case .requested(let n, let m):
            guard case .computed(let m) = m else {
                return .call(m) {this, lookup, result in
                    this = .requested(n: n, m: .computed(result))
                    lookup[m] = result
                }
            }
            if n == 0 {
                lookup[self] = m+1
                return .result(m+1)
            }
            if m == 0 {
                self = .requested(n: n-1, m: .computed(1))
                return .continue
            }
            self = .requested(n: n-1, m: .requested(n: n, m: .computed(m-1)))
            return .continue
        }
    }
    
}

struct Fibonacci : Algorithm {
    
    typealias Output = [Int]
    
    init(_ val: Int) {
        remainingIterations = val - 1
    }
    
    var remainingIterations : Int
    
    static func initialize(_ input: Int) -> (Fibonacci, [Int]) {
        (.init(input), [1, 1])
    }
    
    mutating func step(_ numbers: inout [Int]) -> Continuation<Fibonacci> {
        if remainingIterations <= 0 {
            return .result(numbers)
        }
        remainingIterations -= 1
        numbers.append(numbers.last! + numbers.dropLast().last!)
        return .continue
    }
    
}
