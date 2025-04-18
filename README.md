# Firebase Lua API  

Underwork, but already works.

---

### Getting started

Download the `firebase.lua` and put somewhere.

```lua
local FirebaseAPI = require 'firebase'
local firebase = FirebaseAPI.new(URL, TOKEN)
```

- **`FirebaseAPI.new(url: string, token: string)`**  
  Initializes a new authenticated Firebase API.

---

### Methods

**`:get(path: string)` — `(data: table | nil, error: string | nil)`**

Fetches the value at the specified path in the Firebase Realtime Database.


**`:put(path: string, value: table)` — `(data: table | nil, error: string | nil)`**

Creates or overwrites a value at the given path.

**`:delete(path: string)` — `(nil)`**

Deletes the node at the specified path.

**`:node(path: string)` — `(node: metatable)`**

Returns a special table-like object representing a Firebase node, allowing field access and partial updates through method `:update`.

**`:query(path: string)` — `(query: metatable)`**
Creates a new query object for advanced filtering.

- **`:where(field: string, operator: string, value: any)`** – Adds a filter condition (`==`, `>=`, `<=`, etc.).
- **`:execute() reply table`** – Executes the query and returns matching records.

**`:getMetrics()` — `(metrics: table)`**
Returns internal usage metrics of the Firebase client.

### Practical Examples

##### Insert 50 random users
```lua
for i = 1, 50 do
    firebase:put("users/user"..i, {name = i, age = math.random(122)})
end
```

---

##### Delete users whose keys start with "3"
```lua
local data = firebase:get("users")
for k in next, data do
    if tostring(k):sub(1, 1) == "3" then
        firebase:delete("users/"..k)
    end
end
```
