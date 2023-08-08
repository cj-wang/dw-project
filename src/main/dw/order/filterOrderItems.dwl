%dw 2.0
output application/json

fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order

fun filterLineitem(item) = 
  (vars.splitOrderPEPayload.Product_Order_Items__c splitBy ',') map (
    getCustomAttDetail(item, "configuratorContextKey") contains $
  ) reduce $$ or $

var filteredLineitmes = rootElement."product-lineitems"."product-lineitem"
  filter filterLineitem($)

---
if (payload.orders != null)
  payload update {
    case .orders.order."product-lineitems"."product-lineitem" -> filteredLineitmes
  }
else 
  payload update {
    case .order."product-lineitems"."product-lineitem" -> filteredLineitmes
  }
