%dw 2.0
output application/json
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var shipmentArray = (if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment])
                    filter getCustomAttDetail($, "baseOrderType") != null
var shipmentArraySize = sizeOf(shipmentArray)
---
if(sizeOf(((shipmentArray map getCustomAttDetail($, "baseOrderType")) filter $ != "mobile")) == shipmentArraySize) 
"all-fixed"
else if(sizeOf(((shipmentArray map getCustomAttDetail($, "baseOrderType")) filter $ != "mobile")) > 0)
"mobile+fixed"
else "all-mobile"