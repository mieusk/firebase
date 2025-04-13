# Firebase

Underwork, but already works.

## Simple exemples

To get a value.

```lua
local FirebaseAPI = require 'firebase'
local json = require 'json'

local firebase = FirebaseAPI.new(URL, TOKEN)

--get
local data, err = firebase:get('users/user1')
print(data, err)
```

Or create 50 values
```lua
for i=1, 50 do
    print{firebase:put("users/user"..i, {name = i, age = math.random(122)})}
end
```

Delete values that starts with 3.
```lua
local data = firebase:get('users')
for k in next, data do
    if tostring(k):sub(1, 1) == '3' then
        firebase:delete('users/'..k)
    end
end
```

Update only one value. Manipulate as Lua Table.
```lua
--node
local user = firebase:node('users/user1')
user:update({age = 31})
print(user.name) --get value
```

You can do query too.
```lua
--query
local adults = firebase:query('users')
    :where('age', '>=', 18)
    :execute()
print(adults)
```

Or known in seconds the delay.
```lua
--metric
print {"Average response time: ", firebase:getMetrics().avgResponseTime} 
```

I'll implement more stuff latter, like login through email/password.
