//Copied from SS `Transform Order Composite Request for New or Existing Customer`
%dw 2.0
output application/json

fun p(key) = "value"

fun attributeText(attributeId) = (payload.order.customer.billingAddress.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == attributeId)).customAttribute['text']
var profileContactId = (payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'profileContactId')).customAttribute['text']
fun paymentAttribute(attributeId) = (payload.order.payments.payment.customMethod.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == attributeId)).customAttribute['text']
var hasDIWMSubscription = (payload.order.customAttributes filterObject (payload, index) ->  (payload.'@attributeId' == 'hasDIWMSubscription')).customAttribute['text']
fun getBillingAddress(attributeId) = (payload.order.customer.billingAddress.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == attributeId)).customAttribute['text'] default ""
fun getShippingAddress(attributeId) = (payload.order.shipments.shipment.shippingAddress.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == attributeId)).customAttribute['text'] default ""
var isOutright = (payload.order."customAttributes".*"customAttribute" filter ($."@attributeId" ~= "sales-type"))[0]."text" == "outright" or (payload.order."customAttributes".*"customAttribute" filter ($."@attributeId" ~= "sales-type"))[0]."text" == "outright-plan"
var isSmartSpaces = (payload.order."customAttributes".*"customAttribute" filter ($."@attributeId" ~= "sales-type"))[0]."text" != "outright" or (payload.order."customAttributes".*"customAttribute" filter ($."@attributeId" ~= "sales-type"))[0]."text" != "outright-plan"
var key = if ( isOutright == true ) "Unicart__c" else "Smart_Spaces__c"
var customerId = if ( vars.isOutright ) ((payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'SFCCCustomerId')).customAttribute['text']) else ((payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'smartSpacesSFCCCustomerId')).customAttribute['text'])
var salesType = (payload.order."customAttributes".*"customAttribute" filter ($."@attributeId" ~= "sales-type"))[0]."text"
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
	"Agent_Id__c": (payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'smartSpacesAgentId')).customAttribute['text'],
	"Dealer_Code__c": (payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'smartSpacesDealerCode')).customAttribute['text'],
	"Cart_Id__c": (payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'smartSpacesCartId')).customAttribute['text'],
	"BillingStreet": trim(getBillingAddress('subAddressType') ++ " " ++ getBillingAddress('subAddressNumber') ++ " " ++ getBillingAddress('streetNumber') ++ getBillingAddress('streetNumSuffix') ++ " " ++ getBillingAddress('streetName') ++ " " ++ getBillingAddress('streetType')),
	"BillingCity": payload.order.customer.billingAddress['city'],
	"BillingPostalCode": payload.order.customer.billingAddress['postalCode'],
	"BillingState": payload.order.customer.billingAddress['stateCode'],
	"BillingCountry": p('sf.default.billing.country'),
	"BillingStreetNumber__c": attributeText('streetNumber'),
	"BillingStreetName__c": attributeText('streetName'),
	"BillingStreetType__c": attributeText('streetType'),
	"BillingSubNumber__c": attributeText('subAddressNumber'),
	"BillingSubType__c": attributeText('subAddressType'),
	"Billing_gnafPid__c": attributeText('gnafId'),
	"Billing_ManualAddressType__c": attributeText('manualAddressType'),
	"Status": p('sf.default.order.status'),
	"Payment_Status__c": payload.order.status['paymentStatus'],
	"Net_Price__c": payload.order.shippingLineitems.shippingLineitem['netPrice'],
	"Tax__c": payload.order.shippingLineitems.shippingLineitem['tax'],
	"Gross_Price__c": payload.order.shippingLineitems.shippingLineitem['grossPrice'],
	"Base_Price__c": payload.order.shippingLineitems.shippingLineitem['basePrice'],
	"Tax_Basis__c": payload.order.shippingLineitems.shippingLineitem['taxBasis'],
	"Item_Id__c": payload.order.shippingLineitems.shippingLineitem['itemId'],
	"Tax_Rate__c": payload.order.shippingLineitems.shippingLineitem['taxRate'],
	"Shipping_Method__c": payload.order.shipments.shipment['shippingMethod'],
	"ShippingStreet": trim(getShippingAddress('subAddressType') ++ " " ++ getShippingAddress('subAddressNumber') ++ " " ++ getShippingAddress('streetNumber') ++ getShippingAddress('streetNumSuffix') ++ " " ++ getShippingAddress('streetName') ++ " " ++ getShippingAddress('streetType')),
	"ShippingCity": payload.order.shipments.shipment.shippingAddress['city'],
	"ShippingPostalCode": payload.order.shipments.shipment.shippingAddress['postalCode'],
	"ShippingState": payload.order.shipments.shipment.shippingAddress['stateCode'],
	"ShippingCountry": p('sf.default.shipping.country'),
	"ShippingStreetNumber__c": attributeText('streetNumber'),
	"ShippingStreetName__c": attributeText('streetName'),
	"ShippingStreetType__c": attributeText('streetType'),
	"ShippingSubNumber__c": attributeText('subAddressNumber'),
	"ShippingSubType__c": attributeText('subAddressType'),
	"Shipping_gnafPid__c": attributeText('gnafId'),
	"Shipping_ManualAddressType__c": attributeText('manualAddressType'),
	"SMerch_Net_Price__c": payload.order.shipments.shipment.totals.merchandizeTotal['netPrice'],
	"SMerch_Tax__c": payload.order.shipments.shipment.totals.merchandizeTotal['tax'],
	"SMerch_Gross_Price__c": payload.order.shipments.shipment.totals.merchandizeTotal['grossPrice'],
	"SAdjMerch_Net_Price__c": payload.order.shipments.shipment.totals.adjustedMerchandizeTotal['netPrice'],
	"SAdjMerch_Tax__c": payload.order.shipments.shipment.totals.adjustedMerchandizeTotal['tax'],
	"SAdjMerch_Gross_Price__c": payload.order.shipments.shipment.totals.adjustedMerchandizeTotal['grossPrice'],
	"SShip_Net_Price__c": payload.order.shipments.shipment.totals.shippingTotal['netPrice'],
	"SShip_Tax__c": payload.order.shipments.shipment.totals.shippingTotal['tax'],
	"SShip_Gross_Price__c": payload.order.shipments.shipment.totals.shippingTotal['grossPrice'],
	"SAdjShip_Net_Price__c": payload.order.shipments.shipment.totals.adjustedShippingTotal['netPrice'],
	"SAdjShip_Tax__c": payload.order.shipments.shipment.totals.adjustedShippingTotal['tax'],
	"SAdjShip_Gross_Price__c": payload.order.shipments.shipment.totals.adjustedShippingTotal['grossPrice'],
	"Shipment_Net_Price__c": payload.order.shipments.shipment.totals.shipmentTotal['netPrice'],
	"Shipment_Tax__c": payload.order.shipments.shipment.totals.shipmentTotal['tax'],
	"Shipment_Gross_Price__c": payload.order.shipments.shipment.totals.shipmentTotal['grossPrice'],
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
	(if ( payload.order.payments.payment.creditCard? ) {
		"Payment_Type__c": payload.order.payments.payment.creditCard['cardType'],
		"Card_Number__c": payload.order.payments.payment.creditCard['cardNumber'],
		"Payment_Token__c": payload.order.payments.payment.creditCard['cardToken'],
		"PaymentMethod__c": p('sf.payment.method.id.credit.card'),
		"Card_Holder__c": payload.order.payments.payment.creditCard['cardHolder'],
		"Card_Expiry_Month__c": payload.order.payments.payment.creditCard['expirationMonth'],
		"Card_Expiry_Year__c": payload.order.payments.payment.creditCard['expirationYear']
	}
	else if ( payload.order.payments.payment.customMethod? ) {
		"PaymentMethod__c": if ( payload.order.payments.payment.customMethod['methodName'] == "NoPaymentRequired" ) "No Payment Required" else payload.order.payments.payment.customMethod['methodName'],
		"Paypal_Email__c": paymentAttribute('braintreePaypalEmail'),
		"Payment_Token__c": paymentAttribute('braintreePaymentMethodToken'),
		"Payment_Legacy_Token__c": paymentAttribute('braintreeLegacyPaymentMethodToken'),
		("PayPal_Customer_Id__c": paymentAttribute('braintreeCustomerId')) if (!isEmpty(paymentAttribute('braintreeCustomerId')))
		
	} else {
	}),
	"DIWM_Subscription_Payment__c": if ( hasDIWMSubscription == "true" and !payload.order.customer.customerNo? ) true else false,
	"Amount__c": payload.order.payments.payment['amount'],
	"Processor_Id__c": payload.order.payments.payment['processorId'],
	"Transaction_Id__c": payload.order.payments.payment['transactionId'],
	"Pricebook2Id": p('sf.pricebook2Id.standard'),
	"Optus_Business_Event_Id__c": vars.optusBetId,
	"Device_Total__c": if ( vars.isOutright ) (payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'outrightDeviceCount')).customAttribute['text']
						else
						(payload.order.customAttributes filterObject (payload, index) -> (payload.'@attributeId' == 'smartSpacesDeviceCount')).customAttribute['text'],
	"Bambora_Id__c": customerId,
	"Sales_Type__c": salesType,
	"BillToContactId": "@{newContact.id}"
}

