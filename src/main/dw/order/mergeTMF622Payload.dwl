%dw 2.0
output application/json
---
vars.TMF622Payload ++ 
(vars.createCartPayload - "inputFields") ++
(vars.createCartPayload.inputFields reduce ((item, acc = {}) -> acc ++ item))
