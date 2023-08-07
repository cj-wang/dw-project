%dw 2.0
output application/java
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var isUniCart = (flatten(rootElement."custom-attributes".*"custom-attribute") filter ($."@attribute-id" ~= "isUniCart"))[0]."__text"
---
isUniCart ~= "true"