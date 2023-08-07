%dw 2.0
output application/json
var backDiscount=''
var netDiscount=''
var discountName=''
---
{
    backDiscountName: if ( payload.order.totals.merchandizeTotal.priceAdjustments? ) (payload.order.totals.merchandizeTotal.priceAdjustments.*priceAdjustment map (item,index) -> discountName ++ item['lineitemText']) joinBy ";" else "",
	backDiscount: if ( payload.order.totals.merchandizeTotal.priceAdjustments? ) (payload.order.totals.merchandizeTotal.priceAdjustments.*priceAdjustment map (item,index) -> backDiscount ++ item['grossPrice']) joinBy ";" else "",
	netDiscount: if ( payload.order.totals.merchandizeTotal.priceAdjustments? ) (payload.order.totals.merchandizeTotal.priceAdjustments.*priceAdjustment map (item,index) -> netDiscount ++ item['netPrice']) joinBy ";" else ""
}