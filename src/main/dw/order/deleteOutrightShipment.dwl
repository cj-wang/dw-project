%dw 2.0
output application/json

fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order

var filteredShipments = rootElement."shipments"."shipment"
  filter getCustomAttDetail($, "baseOrderType") != null

---
if (payload.orders != null)
  payload update {
    case .orders.order."shipments"."shipment" -> filteredShipments
  }
else 
  payload update {
    case .order."shipments"."shipment" -> filteredShipments
  }
