# firebase

Underwork, but already works.

- Exemple

```lua
local FirebaseAPI = require 'firebase'
local print = require 'pp' --i use pretty print
local json = require 'json'

local firebase = FirebaseAPI.new(URL, TOKEN)

--get
local data, err = firebase:get('users/user1')
print {data, err}

--put
local success, err = firebase:put('users/user1', {name = 'John', age = 30})

--node
local user = firebase:node('users/user1')
user:update({age = 31})
print(user.name) --get value

--query
local adults = firebase:query('users')
    :where('age', '>=', 18)
    :execute()

print(adults)

--metric
print {"Average response time: ", firebase:getMetrics().avgResponseTime} 
```
