import Foundation
import PlaygroundSupport

/*:
 ## Mutable Data

 Let's start with a jar of 500 dog treats
 */

class Jar {
    var dogTreats = 500
}

/*:
 Now let's say we have a shared manager (singleton) we use throughout our app. This is common practice
 in a lot of iOS apps (even Apple uses it: `URLSession.shared`, `FileManager.default`, etc.). It's a very
 easy way to manage shared state throughout your app.
 */

class DoggyTreatManager {

    let jar: Jar
    let backgroundQueue = DispatchQueue.global(qos: .background)

    init(jar: Jar) {
        self.jar = jar
    }

    func dispenseTreat(forDoggy doggy: String, numberOfTreats: Int) {
        print("\(numberOfTreats) of \(jar.dogTreats) treats about to be consumed by \(doggy).")

        guard jar.dogTreats >= numberOfTreats else {
            print("Not enough treats left for \(doggy)")
            return;
        }

        backgroundQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.someReallyExpensiveCalculation()
            strongSelf.jar.dogTreats -= numberOfTreats

            print("\(numberOfTreats) treats consumed by \(doggy). There are \(strongSelf.jar.dogTreats) left.")
        }
    }

    private func someReallyExpensiveCalculation() {
        Thread.sleep(forTimeInterval: 2)
    }
}

// Singleton, quite common in iOS apps (e.g. NetworkManager, UserDefaultsManager, etc.)
let kitchenJar = Jar()
let doggyStuffManager = DoggyTreatManager(jar: kitchenJar)

doggyStuffManager.dispenseTreat(forDoggy: "Winston", numberOfTreats: 400)
doggyStuffManager.dispenseTreat(forDoggy: "Walter", numberOfTreats: 300)

/**
 OUTPUT:
 300 of 500 treats about to be consumed by Walter.
 400 of 500 treats about to be consumed by Winston.
 400 treats consumed by Winston. There are 100 left.
 300 treats consumed by Walter. There are -200 left.
 ```
*/

/*:
 ## Lock Current Thread

 One way to fix this is by using `NSLock`.
 However, this can be a little risky because if you lock a thread without unlocking it
 (or accidentally lock the same thread twice) you're caught in a **DEADLOCK**. 😱😱😱
 */

let lock = NSLock()
extension DoggyTreatManager {
    func dispenseTreatWithLock(forDoggy doggy: String, numberOfTreats: Int) {

        lock.lock();

        print("\(numberOfTreats) of \(jar.dogTreats) treats about to be consumed by \(doggy).")

        guard jar.dogTreats >= numberOfTreats else {
            print("Not enough treats left for \(doggy)")
            return;
        }

        backgroundQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.someReallyExpensiveCalculation()
            strongSelf.jar.dogTreats -= numberOfTreats

            print("\(numberOfTreats) treats consumed by \(doggy). There are \(strongSelf.jar.dogTreats) left.")

            lock.unlock();
        }
    }
}

let safeKitchenJar = Jar()
let doggyStuffManager2 = DoggyTreatManager(jar: safeKitchenJar)
doggyStuffManager2.dispenseTreatWithLock(forDoggy: "Winston", numberOfTreats: 400)
doggyStuffManager2.dispenseTreatWithLock(forDoggy: "Walter", numberOfTreats: 300)

/**
 OUTPUT
 400 of 500 treats about to be consumed by Winston.
 400 treats consumed by Winston. There are 100 left.
 300 of 100 treats about to be consumed by Walter.
 Not enough treats left for Walter
*/
