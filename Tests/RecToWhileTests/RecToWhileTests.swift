import XCTest
@testable import RecToWhile

final class RecToWhileTests: XCTestCase {
    
    func testEvenOdd() {
        
        for idx in 0..<1000 {
            XCTAssertEqual(EvenOdd.checkEven(numericCast(idx)).run(),
                           idx % 2 == 0)
            XCTAssertEqual(EvenOdd.checkOdd(numericCast(idx)).run(),
                           idx % 2 == 1)
        }
        
    }
    
    func testHanoi() {
        
        for size in 3...10 {
            do {
                let hanoi = Hanoi(size)
                solveHanoi(hanoi)
                XCTAssert(hanoi.isSolved, "pile 1: \(hanoi.pile1), pile 2: \(hanoi.pile2), pile3: \(hanoi.pile3)")
                
            }
            
            do {
                let hanoi = HanoiSolver(game: Hanoi(size)).run()
                XCTAssert(hanoi.isSolved, "pile 1: \(hanoi.pile1), pile 2: \(hanoi.pile2), pile3: \(hanoi.pile3)")
            }
        }
    }
    
    func testAckermann() {
        
        for i in 0...3 {
            for j in 0...9 {
                XCTAssertEqual(ackermannRec(numericCast(i), numericCast(j)),
                               Ackermann.requested(n: numericCast(i), m: .computed(numericCast(j))).run())
            }
        }
        
    }
    
}

enum EvenOdd : Algorithm {
    
    case checkEven(UInt)
    case checkOdd(UInt)
    
    var continuation: Continuation<EvenOdd, Bool> {
        switch self {
        case .checkEven(let int):
            if int == 0 {
                return .result(true)
            }
            return .expand(.checkOdd(int - 1))
        case .checkOdd(let int):
            if int == 0 {
                return .result(false)
            }
            return .expand(.checkEven(int - 1))
        }
    }
    
    mutating func onReturn(_ subResult: Bool) {
        fatalError()
    }
    
}

final class Hanoi {
    
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
    
    @discardableResult
    func move(from: PileIdx, to: PileIdx) -> Hanoi {
        guard !self[from].isEmpty else {return self}
        guard self[to].isEmpty || self[from].last! > self[to].last! else {return self}
        let elm = self[from].removeLast()
        self[to].append(elm)
        return self
    }
    
    var isSolved : Bool {
        pile1.isEmpty && pile2.isEmpty && pile3 == pile3.sorted()
    }
    
}

func solveHanoi(_ hanoi: Hanoi) {
    moveAll(hanoi: hanoi, amount: hanoi.pile1.count, from: .first, to: .third, via: .second)
}

func moveAll(hanoi: Hanoi,
             amount: Int,
             from: Hanoi.PileIdx,
             to: Hanoi.PileIdx,
             via: Hanoi.PileIdx) {
    if amount <= 0 {
        return
    }
    moveAll(hanoi: hanoi, amount: amount - 1, from: from, to: via, via: to)
    hanoi.move(from: from, to: to)
    moveAll(hanoi: hanoi, amount: amount - 1, from: via, to: to, via: from)
}

struct HanoiSolver : Algorithm {
    
    let game : Hanoi
    var state : State = .newGame
    
    enum State {
        case newGame
        case moving(Move)
        case done
    }
    
    enum MoveStage {
        case first, second, third
    }
    
    struct Move {
        let amount : Int
        let from : Hanoi.PileIdx
        let to : Hanoi.PileIdx
        let via : Hanoi.PileIdx
        var stage : MoveStage = .first
    }
    
    var continuation: Continuation<HanoiSolver, Hanoi> {
        switch state {
        case .newGame:
            return .expand(HanoiSolver(game: game,
                                       state: .moving(Move(amount: game.pile1.count,
                                                           from: .first,
                                                           to: .third,
                                                           via: .second))))
        case .moving(var move):
            if move.amount <= 0 {
                return .result(game)
            }
            switch move.stage {
            case .first:
                return .call(HanoiSolver(game: game,
                                         state: .moving(Move(amount: move.amount - 1,
                                                             from: move.from,
                                                             to: move.via,
                                                             via: move.to))))
            case .second:
                move.stage = .third
                return .expand(HanoiSolver(game: game.move(from: move.from, to: move.to),
                                           state: .moving(move)))
            case .third:
                return .call(HanoiSolver(game: game,
                                         state: .moving(Move(amount: move.amount - 1,
                                                             from: move.via,
                                                             to: move.to,
                                                             via: move.from))))
            }
        case .done:
            return .result(game)
        }
    }
    
    mutating func onReturn(_ subResult: Hanoi) {
        guard case .moving(var move) = state else {
            fatalError()
        }
        switch move.stage {
        case .first:
            move.stage = .second
            state = .moving(move)
        case .second:
            fatalError()
        case .third:
            state = .done
        }
    }
    
}

func ackermannRec(_ n: UInt, _ m: UInt) -> UInt {
    
    if n == 0 {
        return m+1
    }
    if m == 0 {
        return ackermannRec(n-1, 1)
    }
    return ackermannRec(n-1, ackermannRec(n, m-1))
    
}

enum Ackermann : Algorithm {
    
    indirect case requested(n: UInt, m: Ackermann)
    case computed(UInt)
    
    var continuation: Continuation<Ackermann, UInt> {
        switch self {
        case .requested(let n, let m):
            guard case .computed(let m) = m else {
                return .call(m)
            }
            if n == 0 {
                return .result(m+1)
            }
            if m == 0 {
                return .expand(.requested(n: n-1, m: .computed(1)))
            }
            return .expand(.requested(n: n-1, m: .requested(n: n, m: .computed(m-1))))
        case .computed(let result):
            return .result(result)
        }
    }
    
    mutating func onReturn(_ subResult: UInt) {
        guard case .requested(let n, _) = self else {
            fatalError()
        }
        self = .requested(n: n, m: .computed(subResult))
    }
    
}
