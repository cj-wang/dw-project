%dw 2.0
output application/json
import * from dw::util::Values
var filteredPaymentObj = (payload.order.payments.*payment filter (!isEmpty($."credit-card")))[0]
---
payload update ["order", "payments"] with {
    "payment": filteredPaymentObj
}