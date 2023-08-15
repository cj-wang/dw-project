%dw 2.0
output application/json
import * from dw::util::Values
fun filterProducts(arr) = (([arr] map (item, itemIndex) -> {
    "custom-attribute": ((item.*"custom-attribute") map (attribute, attributeIndex) -> {
        (attribute."@attribute-id"): attribute."__text"
    }) reduce ($$ ++ $)
})."custom-attribute") reduce ($$ ++ $)
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var trimmedOrderPayload = (rootElement.*"product-lineitems".*"product-lineitem" update ["custom-attributes"] with filterProducts($))
var outrightProductIds = (trimmedOrderPayload filter $."custom-attributes"."isOutrightDevice" ~= "true") map (
    "lineItem": $."product-id"
).lineItem
var outrightProductLineitems = (rootElement."product-lineitems".*"product-lineitem" filter (outrightProductIds contains $."product-id") map (
    "product-lineitem": $
)) reduce ($$ ++ $)
---
{
	"order": rootElement update ["product-lineitems"] with outrightProductLineitems
}