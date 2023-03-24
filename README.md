# swift-atomic

## A thread safe property decorator  in swift.

### usage
``` swift
final class AtomicTests: XCTestCase {
    @Atomic var counter:Int = 0
    @Atomic var dic:[Int:Int] = [:]
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let group = DispatchGroup()
        for i in 0..<10{
            group.enter()
            DispatchQueue(label: "\(i)").async {
                self.counter += 1
                self.$dic.write {
                    $0[0] = self.counter
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertTrue(self.counter == 10)
        XCTAssertTrue(self.dic[0] == 10)
    }
}

```
