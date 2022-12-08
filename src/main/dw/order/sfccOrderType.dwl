%dw 2.0
output application/json skipNullOn="everywhere"
import * from dw::core::Arrays
import * from dw::core::Strings
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
// Function to get custom-attribute value
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var relocationFlowType = if (getCustomAttDetail(rootElement, "baseOrderType") == "relocation" and getCustomAttDetail(rootElement, "flowType") == "OFFLINE") "RelocationOffline" 
else if (getCustomAttDetail(rootElement, "baseOrderType") == "relocation" and getCustomAttDetail(rootElement, "flowType") == "ONLINE") "RelocationOnline" 
else if (getCustomAttDetail(rootElement, "baseOrderType") == "mobile") "Mobile" 
else "non_Relocation"
---
//vars.createCustomerPayload.customerRelocation.RelocationFlowType 
relocationFlowType