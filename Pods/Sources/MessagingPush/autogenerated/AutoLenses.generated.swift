// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable all

import CioInternalCommon
import CioTracking
import Foundation

/**
 ######################################################
 Documentation
 ######################################################

 This automatically generated file you are viewing is to modify immutable objects in a convenient way.

 * What do you mean modify immutable objects? https://apiumhub.com/tech-blog-barcelona/lenses-swift-immutability-objects/

 * How do I use this?

 ```
 // Add `AutoLenses` protocol to struct.
 struct Foo: AutoLenses {
   // properties be `let` to be immutable
   let bar: String
   let bar2: Bool
 }

 var foo = Foo(bar: "X", bar2: true)
 // Now, we want to modify `foo.bar` but it's immutable. How do I modify `bar` without having to do something messy like...
 Foo(bar: "new value", bar2: oldInstance.bar2)
 ...to leave my other properties alone?

 foo = foo.setBar("new value")
 // Now, `foo` is set to the brand new instanced of `Foo` while copying over all other values of `Foo` from the old instance.
 ```

 */

infix operator *~: MultiplicationPrecedence
infix operator |>: AdditionPrecedence

struct Lens<Whole, Part> {
    let get: (Whole) -> Part
    let set: (Part, Whole) -> Whole
}

func * <A, B, C>(lhs: Lens<A, B>, rhs: Lens<B, C>) -> Lens<A, C> {
    Lens<A, C>(
        get: { a in rhs.get(lhs.get(a)) },
        set: { c, a in lhs.set(rhs.set(c, lhs.get(a)), a) }
    )
}

func *~ <A, B>(lhs: Lens<A, B>, rhs: B) -> (A) -> A {
    { a in lhs.set(rhs, a) }
}

func |> <A, B>(x: A, f: (A) -> B) -> B {
    f(x)
}

func |> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    { g(f($0)) }
}

extension CioPushPayload.Push {
    static let linkLens = Lens<CioPushPayload.Push, String?>(
        get: { $0.link },
        set: { link, existing in
            CioPushPayload.Push(link: link, image: existing.image)
        }
    )
    static let imageLens = Lens<CioPushPayload.Push, String?>(
        get: { $0.image },
        set: { image, existing in
            CioPushPayload.Push(link: existing.link, image: image)
        }
    )

    // Convenient set functions to edit a property of the immutable object
    func linkSet(_ link: String?) -> CioPushPayload.Push {
        CioPushPayload.Push(link: link, image: image)
    }

    func imageSet(_ image: String?) -> CioPushPayload.Push {
        CioPushPayload.Push(link: link, image: image)
    }
}

// swiftlint:enable all
