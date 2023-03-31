import XCTest
@testable import Atomic
import Foundation

enum Test:Equatable{
    case a
    case b
    case c(Int)
    func add()->Test{
        switch self{
        case .a:
            return .b
        case .b:
            return .c(0)
        case .c(let i):
            print(i)
            return .c(i+1)
        }
    }
}
class Example:NSObject {
    let lock = AtomLock()
    var threads:[Thread] = []
    var threads1:[Thread] = []
    @Atomic var counter:Int = 0
    @Atomic var dic:[Int:Int] = [0:0]
    @Atomic var test:Test = .a
    let group = DispatchGroup()
    override init() {
        super.init()
        self.threads = (0..<4).map { i in
            group.enter()
            return Thread(target: self, selector: #selector(run), object: nil)
        }
        self.threads1 = (0..<4).map { i in
            group.enter()
            return Thread(target: self, selector: #selector(run1), object: nil)
        }
    }
    @objc func run(){
        self.$dic.write { d in
            d[0] = d[0]! + 1
        }
//        self.$dic[0] = self.$dic[0]! + 1  // not safe  maybe error
//        self.dic[0] = self.dic[0]! + 1 // not safe  maybe error
        self.$test.write {
            $0 = $0.add()
        }
//        self.test = self.test.add() // not safe  maybe error
        self.counter += 1 // this is safe in swift even without @Atomic
        group.leave()
    }
    @objc func run1(){
        lock.lock(); defer{lock.unlock()}
        self.counter -= 1
        group.leave()
    }
    func go() {
        threads.forEach { t in
            t.start()
        }
        threads1.forEach { t in
            t.start()
        }
        group.wait()
        XCTAssertTrue(counter == 0)
        XCTAssertTrue(self.dic[0] == 4)
        XCTAssertTrue(self.test == .c(2))
    }
}
final class AtomicTests: XCTestCase{
    func test(){
        Example().go()
    }
}
