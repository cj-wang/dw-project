%dw 2.0
output application/json

var filteredData = payload.OrderingCategory filter !isEmpty($.CategoryRef[0].ProductRef.ProductSpecID)
var groupedBySpecId = {(
    filteredData map {(
        flatten($.CategoryRef[0].ProductRef.ProductSpecID)  map (prodSpecId) -> {
            ($.Name): prodSpecId
        }
    )}
)} groupBy $
---
groupedBySpecId mapObject ($$): keysOf($)