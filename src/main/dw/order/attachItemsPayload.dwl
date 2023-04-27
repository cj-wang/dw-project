%dw 2.0
import * from dw::core::Strings
output application/json
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var shipmentArray = if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment]
// var serviceDetails = ({(flatten(shipmentArray) filter (getCustomAttDetail($."shipping-address", "addressType")== "SERVICE"))}) default null
var parentName = vars.parentProductName[0].parentName
//var aemHandoverPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "aemHandoverPayload"))[0]."__text") default "{}"), "application/json")
//var addressMatchType = if (!isEmpty((aemHandoverPayload filterObject (value, key) -> (key contains "baseDetails-") and (value.product[0].technology contains ("NBN"))))) ((aemHandoverPayload filterObject (value, key) -> (key contains "baseDetails-") and (value.product[0].technology contains ("NBN")))[0].planDetails.addressMatchType) else null
//var sqPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "serviceQualification"))[0]."__text") default "{}"), "application/json")
//var nbnLocationId = ((sqPayload filterObject ($$ contains("LOC"))) pluck ($$))[0]
var PlanBillingOfferId = getCustomAttDetail(rootElement,"planBillingOfferId") default ""
//var gnafid = sqPayload."$(PlanBillingOfferId)" default ""
//var originalSqResult = (sqPayload[1].response.checkServiceCoverageResponse.services.service filter ((lower($.family) == "nbn fttp") or (lower($.family) == "nbn cable (hfc)")))[0]
//var originalSqResult = if (!isEmpty(sqPayload)) sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service filter ((lower($.family) == "nbn fttp") or (lower($.family) == "nbn cable (hfc)")) else ""
//var originalSqResultFV = if (!isEmpty(sqPayload)) sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service else ""
var networkTechnology = (rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "technology"))[0]."__text"
var numberPortabilityCheckResponse = if (!isEmpty(getCustomAttDetail(rootElement, "numberPortabilityCheckResponse"))) (read(getCustomAttDetail(rootElement, "numberPortabilityCheckResponse"), "application/json")) else null
fun convertObjectToArray(val) =
    if (typeOf(val) ~= "Object")
        (val as Object) pluck { ($$): $ }
    else
        val
fun repeatItemsBasedOnQty(val) =
	flatten(val map ((item, index) ->
	    (0 to item.quantity - 1) map item
	))
//var dsqDetails = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "dsqDetails"))[0]."__text") default "{}"), "application/json")
//var dsqDetailsInfo = dsqDetails.dsqDetails35287684.dsqSpeedDetails
//var sqPayloadUpstreamUnit = sqPayload.LOC220777000281.response.serviceCharacteristics.NBN_VDSL_MAX_UPSTREAM_SPEED_UNIT_OF_MEASURE
//var sqPayloadDownstreamtreamUnit = sqPayload.LOC220777000281.response.serviceCharacteristics.NBN_VDSL_MAX_DOWNSTREAM_SPEED_UNIT_OF_MEASURE

var configContextKeyArr = (rootElement."product-lineitems"."product-lineitem") map ($."custom-attributes"."custom-attribute") filter (($."@attribute-id" contains "sfccProductType") and ($."__text" contains "OFFER")) map ($ filter ($."@attribute-id" contains "configuratorContextKey") map ($."__text"))[0]
var mobileProductTypeArray = [
    "Fixed Broadband",
    "Mobile",
    "Mobile Broadband",
    "Mobile and Mobile Broadband"
]
---
configContextKeyArr map (item1, index1) -> (
{
	flowtype:vars.sfccOrderType,
	parentItems: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
	"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productOfferId')[0]."__text",
	"sfccProductType" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
    "parentName" : item."product-name",
    "contractDuration": vars.basePlanContractDuration.contractDuration,
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text"
	})) filter ($.sfccProductType[0] == "OFFER" and item1 == $.configKey)
    //map shipment data 
	map(ProductOfferItem) -> (ProductOfferItem ++ (
	((shipmentArray) map (item) -> ({
		
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text",
    "transactionType":  if ((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'transactionType')[0]."__text" =="RECON")"Recontract" else (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'transactionType')[0]."__text",
    "orderType": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'baseOrderType')[0]."__text",
    "existingServiceProductInstanceId": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'existingServiceProductInstanceId')[0]."__text",
    "serviceRequestDate": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceRequestDate')[0]."__text",
    "deliveryDate": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'deliveryDate')[0]."__text"
	})) filter (item1 == $.configKey))[0]),
	//end shipment data

    childItems: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
    //"itemId" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	
	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
	//"sfccProductType" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
    "sfccProductType" : (convertObjectToArray(item."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
    
    "productName" : if(!isEmpty(item."bundled-product-lineitems"."bundled-product-lineitem"."product-name")) (item."bundled-product-lineitems"."bundled-product-lineitem"."product-name")
                    else (item."product-name"),
    "contractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text",
    "isPromotionItem": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'mecDiscountId')[0]."__text",
    "quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null,
    "BillingOfferID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferId')[0]."__text",
    "BillingOfferPOID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferPOId')[0]."__text",
    "BillingOfferPRID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferParentRelationId')[0]."__text",
    "BillingOfferPSRID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productSpecRelationId')[0]."__text",
    "BillingOfferRelationID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferRelationId')[0]."__text",
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text"
	})) filter (($.sfccProductType[0] != "OFFER" or $.sfccProductType[0] != "SIMPLE_PRODUCT" ) and item1 == $.configKey and $.itemId != null and isEmpty($.isPromotionItem)))),
	
	childItemsWithDiscount: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
    //"itemId" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	
	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
	//"sfccProductType" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
    "sfccProductType" : (convertObjectToArray(item."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
    
    "productName" : if(!isEmpty(item."bundled-product-lineitems"."bundled-product-lineitem"."product-name")) (item."bundled-product-lineitems"."bundled-product-lineitem"."product-name")
                    else (item."product-name") ,
    "contractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text",
    "isPromotionItem": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'mecDiscountId')[0]."__text",
    "quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null,
    "BillingOfferID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferId')[0]."__text",
    "BillingOfferPOID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferPOId')[0]."__text",
    "BillingOfferPRID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferParentRelationId')[0]."__text",
    "BillingOfferPSRID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productSpecRelationId')[0]."__text",
    "BillingOfferRelationID": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferRelationId')[0]."__text",
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text"
	})) filter (($.sfccProductType[0] != "OFFER" or $.sfccProductType[0] != "SIMPLE_PRODUCT" ) and item1 == $.configKey and $.itemId != null and !isEmpty($.isPromotionItem)))),
	
	simpleProducts: repeatItemsBasedOnQty(((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
    "itemId" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'simpleProductId')[0]."__text",
	"sfccProductType" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
   "contractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text",
	"planContractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'planContractDuration')[0]."__text",
	"configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text",
	//"installationMethod": if((flatten(rootElement.shipments.shipment."custom-attributes"."custom-attribute") filter $."@attribute-id"=="optusAppointmentRequired")[0]."__text" == "true") "Professional Install" else "SelfInstall"
	
	"quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null,
	"billingOfferId": (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	})) filter ($.sfccProductType[0] == "SIMPLE_PRODUCT" and item1 == $.configKey))
	//map shipment data 
	map(simpleProductItem) -> (simpleProductItem ++ (
	((shipmentArray) map (item) -> ({
		
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text",
    "selectedSimType":  if ( lower((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text") == "physical" ) "USIM"
    					else if ( lower((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text") == "esim" ) "ESIM"
    					else (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text"
	})) filter (item1 == $.configKey))[0]),
	//end shipment data
	
	productAttributes: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({    
    "sfccProductType" : (convertObjectToArray(item."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",     
    "quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null,
    "upgradeFee": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'upgradeFee')[0]."__text",
    "feeIndicator": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'feeIndicator')[0]."__text",    
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text"
	})) filter (isEmpty(($.sfccProductType[0] )) and item1 == $.configKey))),
	
	mobileSpecs: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
		"configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text",
        "itemId": (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
    	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
    	"productType": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "productType"))[0]."__text",
    	"offerFamily": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "offerFamily"))[0]."__text",
    	"billingOfferId": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "billingOfferId"))[0]."__text",
    	"contractDuration": if ( mobileProductTypeArray map $ contains (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productType')[0]."__text" )
    						(item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text"
    						else null
	})) filter ($.itemId != null and $.isBasePlan ~= "true" and item1 == $.configKey and (mobileProductTypeArray map $ contains $.productType))
	
	//map shipment data 
	map(mobileSpecItem) -> (mobileSpecItem ++ (
	((shipmentArray) map (item) -> ({
		
    "configKey": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'configuratorContextKey')[0]."__text",
    "serviceNickname" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceNickname')[0]."__text",
    "shippingMethod" : item."shipping-method" default "",
    "portingRequestIndicator" : if ((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceKeepMobileNumber')[0]."__text" == "YES") "Yes"
    							else if ((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceKeepMobileNumber')[0]."__text" == "NO") "No"
    							else null,
    "allocatedNumber" : if ((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceKeepMobileNumber')[0]."__text" == "NO") 
    							(item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceMobileNumber')[0]."__text" replace " " with "" default null
    						else null,
    "rlcMsisdn": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceMobileNumber')[0]."__text" replace " " with "" default null,
    "msnBcc" : if ((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceKeepMobileNumber')[0]."__text" == "YES") 
    							(item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceMobileNumber')[0]."__text" replace " " with "" default null
    						else null,
    "serviceAccountNumber": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceAccountNumber')[0]."__text" replace " " with "" default null,
    "serviceDateOfBirth": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'serviceDateOfBirth')[0]."__text",
    "selectedSimType":  if ( lower((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text") == "physical" ) "USIM"
    					else if ( lower((item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text") == "esim" ) "ESIM"
    					else (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'selectedSimType')[0]."__text",
    "ppvChallengerId" : (read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "prePortVerificationRequest"))[0]."__text") default "{}"), "application/json")).challengerId default null,
    "ppvMethod": (read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "prePortVerificationRequest"))[0]."__text") default "{}"), "application/json")).ppvMethod default null,
    "hasShippable": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'hasShippable')[0]."__text" as Boolean default false
	})) filter (item1 == $.configKey) orderBy (! $.hasShippable) )[0])  // DOP-3109 take hasShippable=true as preference
	//end shipment data
	
})