//Copied from SS `Transform Order Composite Request for New or Existing Customer`
%dw 2.0
output application/json

fun getObject(o) = if (o is Array) o[0] else o
var shippingLineitem = getObject(payload.order.shippingLineitems.shippingLineitem)
var shipment = getObject(payload.order.shipments.shipment)
var payment = getObject(payload.order.payments.payment)

fun attributeText(attributeId) = (flatten(payload.order.customer.billingAddress."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == attributeId))[0]."text"
var profileContactId = (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'profileContactId'))[0]."text"
fun paymentAttribute(attributeId) = (flatten(payment.customMethod."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == attributeId))[0]."text"
var hasDIWMSubscription = (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) ->  (payload.'@attributeId' == 'hasDIWMSubscription'))[0]."text"
fun getBillingAddress(attributeId) = (flatten(payload.order.customer.billingAddress."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == attributeId))[0]."text" default ""
fun getShippingAddress(attributeId) = (flatten(shipment.shippingAddress."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == attributeId))[0]."text" default ""
var isOutright = (flatten(payload.order."customAttributes".*"customAttribute") filter ($."@attributeId" ~= "sales-type"))[0]."text" == "outright" or (flatten(payload.order."customAttributes".*"customAttribute") filter ($."@attributeId" ~= "sales-type"))[0]."text" == "outright-plan"
var isSmartSpaces = (flatten(payload.order."customAttributes".*"customAttribute") filter ($."@attributeId" ~= "sales-type"))[0]."text" != "outright" or (flatten(payload.order."customAttributes".*"customAttribute") filter ($."@attributeId" ~= "sales-type"))[0]."text" != "outright-plan"
var key = if ( isOutright == true ) "Unicart__c" else "Smart_Spaces__c"
var customerId = if ( isOutright ) ((flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'SFCCCustomerId'))[0]."text") else ((flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'smartSpacesSFCCCustomerId'))[0]."text")
var salesType = (flatten(payload.order."customAttributes".*"customAttribute") filter ($."@attributeId" ~= "sales-type"))[0]."text"
---
{
	"AccountId": '@{newAccount.id}',
	"Name": if ( !isEmpty(payload.order['@orderNo']) ) (payload.order['@orderNo']) else if ( !isEmpty(payload.order['originalOrderNo']) ) (payload.order['originalOrderNo']) else (payload.order['currentOrderNo']),
	"ExternalOrderNo__c": payload.order['@orderNo'],
	"Order_DateTime__c": payload.order['orderDate'],
	"EffectiveDate": (payload.order['orderDate'] >> "Australia/Sydney") as Date,
	"Invoice__c": payload.order['invoiceNo'],
	"Currency__c": payload.order['currency'],
	"Taxation__c": payload.order['taxation'],
	"Agent_Id__c": (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'smartSpacesAgentId'))[0]."text",
	"Dealer_Code__c": (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'smartSpacesDealerCode'))[0]."text",
	"Cart_Id__c": (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'smartSpacesCartId'))[0]."text",
	"BillingStreet": trim(getBillingAddress('subAddressType') ++ " " ++ getBillingAddress('subAddressNumber') ++ " " ++ getBillingAddress('streetNumber') ++ getBillingAddress('streetNumSuffix') ++ " " ++ getBillingAddress('streetName') ++ " " ++ getBillingAddress('streetType')),
	"BillingCity": payload.order.customer.billingAddress['city'],
	"BillingPostalCode": payload.order.customer.billingAddress['postalCode'],
	"BillingState": payload.order.customer.billingAddress['stateCode'],
	// "BillingCountry": p('sf.default.billing.country'),
	"BillingStreetNumber__c": attributeText('streetNumber'),
	"BillingStreetName__c": attributeText('streetName'),
	"BillingStreetType__c": attributeText('streetType'),
	"BillingSubNumber__c": attributeText('subAddressNumber'),
	"BillingSubType__c": attributeText('subAddressType'),
	"Billing_gnafPid__c": attributeText('gnafId'),
	"Billing_ManualAddressType__c": attributeText('manualAddressType'),
	// "Status": p('sf.default.order.status'),
	"Payment_Status__c": payload.order.status['paymentStatus'],
	"Net_Price__c": shippingLineitem['netPrice'],
	"Tax__c": shippingLineitem['tax'],
	"Gross_Price__c": shippingLineitem['grossPrice'],
	"Base_Price__c": shippingLineitem['basePrice'],
	"Tax_Basis__c": shippingLineitem['taxBasis'],
	"Item_Id__c": shippingLineitem['itemId'],
	"Tax_Rate__c": shippingLineitem['taxRate'],
	"Shipping_Method__c": shipment['shippingMethod'],
	// "ShippingStreet": trim(getShippingAddress('subAddressType') ++ " " ++ getShippingAddress('subAddressNumber') ++ " " ++ getShippingAddress('streetNumber') ++ getShippingAddress('streetNumSuffix') ++ " " ++ getShippingAddress('streetName') ++ " " ++ getShippingAddress('streetType')),
	"ShippingCity": shipment.shippingAddress['city'],
	"ShippingPostalCode": shipment.shippingAddress['postalCode'],
	"ShippingState": shipment.shippingAddress['stateCode'],
	// "ShippingCountry": p('sf.default.shipping.country'),
	"ShippingStreetNumber__c": attributeText('streetNumber'),
	"ShippingStreetName__c": attributeText('streetName'),
	"ShippingStreetType__c": attributeText('streetType'),
	"ShippingSubNumber__c": attributeText('subAddressNumber'),
	"ShippingSubType__c": attributeText('subAddressType'),
	"Shipping_gnafPid__c": attributeText('gnafId'),
	"Shipping_ManualAddressType__c": attributeText('manualAddressType'),
	"SMerch_Net_Price__c": shipment.totals.merchandizeTotal['netPrice'],
	"SMerch_Tax__c": shipment.totals.merchandizeTotal['tax'],
	"SMerch_Gross_Price__c": shipment.totals.merchandizeTotal['grossPrice'],
	"SAdjMerch_Net_Price__c": shipment.totals.adjustedMerchandizeTotal['netPrice'],
	"SAdjMerch_Tax__c": shipment.totals.adjustedMerchandizeTotal['tax'],
	"SAdjMerch_Gross_Price__c": shipment.totals.adjustedMerchandizeTotal['grossPrice'],
	"SShip_Net_Price__c": shipment.totals.shippingTotal['netPrice'],
	"SShip_Tax__c": shipment.totals.shippingTotal['tax'],
	"SShip_Gross_Price__c": shipment.totals.shippingTotal['grossPrice'],
	"SAdjShip_Net_Price__c": shipment.totals.adjustedShippingTotal['netPrice'],
	"SAdjShip_Tax__c": shipment.totals.adjustedShippingTotal['tax'],
	"SAdjShip_Gross_Price__c": shipment.totals.adjustedShippingTotal['grossPrice'],
	"Shipment_Net_Price__c": shipment.totals.shipmentTotal['netPrice'],
	"Shipment_Tax__c": shipment.totals.shipmentTotal['tax'],
	"Shipment_Gross_Price__c": shipment.totals.shipmentTotal['grossPrice'],
	"OMerch_Net_Price__c": payload.order.totals.merchandizeTotal['netPrice'],
	"OMerch_Tax__c": payload.order.totals.merchandizeTotal['tax'],
	"OMerch_Gross_Price__c": payload.order.totals.merchandizeTotal['grossPrice'],
	"Back_Discount__c": vars.cartDiscounts['backDiscount'],
	"Back_Discount_Name__c": vars.cartDiscounts['backDiscountName'],
	"Net_Discount__c": vars.cartDiscounts['netDiscount'],
	"OAdjMerch_Net_Price__c": payload.order.totals.adjustedMerchandizeTotal['netPrice'],
	"OAdjMerch_Tax__c": payload.order.totals.adjustedMerchandizeTotal['tax'],
	"OAdjMerch_Gross_Price__c": payload.order.totals.adjustedMerchandizeTotal['grossPrice'],
	"OShip_Net_Price__c": payload.order.totals.shippingTotal['netPrice'],
	"OShip_Tax__c": payload.order.totals.shippingTotal['tax'],
	"OShip_Gross_Price__c": payload.order.totals.shippingTotal['grossPrice'],
	"OAdjShip_Net_Price__c": payload.order.totals.adjustedShippingTotal['netPrice'],
	"OAdjShip_Tax__c": payload.order.totals.adjustedShippingTotal['tax'],
	"OAdjShip_Gross_Price__c": payload.order.totals.adjustedShippingTotal['grossPrice'],
	"Order_Net_Price__c": payload.order.totals.orderTotal['netPrice'],
	"Order_Tax__c": payload.order.totals.orderTotal['tax'],
	"Order_Gross_Price__c": payload.order.totals.orderTotal['grossPrice'],
	(if ( payment.creditCard? ) {
		"Payment_Type__c": payment.creditCard['cardType'],
		"Card_Number__c": payment.creditCard['cardNumber'],
		"Payment_Token__c": payment.creditCard['cardToken'],
		// "PaymentMethod__c": p('sf.payment.method.id.credit.card'),
		"PaymentMethod__c": "Credit Card",
		"Card_Holder__c": payment.creditCard['cardHolder'],
		"Card_Expiry_Month__c": payment.creditCard['expirationMonth'],
		"Card_Expiry_Year__c": payment.creditCard['expirationYear']
	}
	else if ( payment.customMethod? ) {
		"PaymentMethod__c": if ( payment.customMethod['methodName'] == "NoPaymentRequired" ) "No Payment Required" else payment.customMethod['methodName'],
		"Paypal_Email__c": paymentAttribute('braintreePaypalEmail'),
		"Payment_Token__c": paymentAttribute('braintreePaymentMethodToken'),
		"Payment_Legacy_Token__c": paymentAttribute('braintreeLegacyPaymentMethodToken'),
		("PayPal_Customer_Id__c": paymentAttribute('braintreeCustomerId')) if (!isEmpty(paymentAttribute('braintreeCustomerId')))
		
	} else {
	}),
	"DIWM_Subscription_Payment__c": if ( hasDIWMSubscription == "true" and !payload.order.customer.customerNo? ) true else false,
	"Amount__c": payment['amount'],
	"Processor_Id__c": payment['processorId'],
	"Transaction_Id__c": payment['transactionId'],
	// "Pricebook2Id": p('sf.pricebook2Id.standard'),
	"Pricebook2Id": "01s5m0000000O3cAAE",
	// "Optus_Business_Event_Id__c": vars.optusBetId,
	"Device_Total__c": if ( isOutright ) (flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'outrightDeviceCount'))[0]."text"
						else
						(flatten(payload.order."customAttributes".*"customAttribute") filter (payload, index) -> (payload.'@attributeId' == 'smartSpacesDeviceCount'))[0]."text",
	"Bambora_Id__c": customerId,
	"Sales_Type__c": salesType,
	"BillToContactId": "@{newContact.id}"
}
