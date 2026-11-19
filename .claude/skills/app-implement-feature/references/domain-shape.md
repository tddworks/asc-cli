# Think the domain first

Before any change, a fix too, ask how the domain should be, not only where the
line fits. The aim is a domain that is **easy to understand**: someone new
reads a type's surface and can explain it in the user's words. Borrow from DDD
only what serves that; no pattern is added for its own sake.

The tree, the words, every law and its owner are in `docs/CANONICAL_MODEL.md`;
the Swift patterns in [domain-models.md](domain-models.md).

## Five questions, of every type the change touches

**1. Would the user say it?**
Names come from what the user sees (the screens, the CLI, the API), never the
mechanism. If the facts need a concept the code doesn't have, it is hiding as
an optional or a flag. *"Cancellable" is a word users meet; `statusCode < 3`
is not.*

**2. Does the thing decide about itself?**
A rule lives on the thing it is about; callers tell it, they don't read its
state and decide. *Three views writing `order.status == .pending ||
order.status == .processing` means the rule is `Order.canBeCancelled`, and
callers ask for it.*

**3. Can you see every state?**
Each state a user can meet is a case with its data; one value never means two
things. *A payment that timed out may have gone through: it is `unconfirmed`,
not `failed`. A missing answer is a case (`unknown`), not a thrown error.*

**4. Is it as small as it can be?**
A value when it is data with rules; an actor or class only when it changes
over time; a `@Mockable` protocol only at the outside world (a network, a
database, a process), named for its role. No type, layer or flag the change
doesn't need — but never drop a rule the domain keeps.

**5. Is what differs between cases data?**
A table, a value, a registration — never `if kind == "premium"` or a subclass
per variant. *A shipping rule per country is a lookup in `ShippingRates`, not
a `switch` in the checkout view.*

## Check by concept

The five questions look at one type. To find what is wrong across the domain,
check each **concept folder** as a whole. Each row names a smell you can grep
for.

| # | Ask | The smell |
|---|---|---|
| 1 | **Does anything cross the fence?** Only a public face or an id may | another concept's `Internal/` type used here; `App/` building an adapter it should only wire |
| 2 | **Does every word mean one thing here?** | one name for two facts |
| 3 | **Does every law have one owner?** | the same rule written twice, drifting; a caller reading state to decide |
| 4 | **Is the business above, and the technique below?** | a request, SQL or JSON assembled in the public face or in `App/`; a domain decision in `Internal/System/` |
| 5 | **Does a new case add data, not an edit?** | a `switch` on a variant name; one type changing for several reasons |
| 6 | **Does the question have a home?** | a rule that lives only in a doc, a view, or a comment |

A finding goes in `CANONICAL_MODEL.md`: as a fix when a law already says what
is right, or as an open question when the design must decide first.

## Keep it in scope

- Fix what these questions find **in the types the change touches**, test
  first. Record the rest in `CANONICAL_MODEL.md` for its own change.
- A new aggregate, a moved law or a changed owner is a design change: write it
  into `CANONICAL_MODEL.md` first, as part of the Phase 0 design.
