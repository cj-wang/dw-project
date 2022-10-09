%dw 2.0
import * from dw::core::Strings
output application/json
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var shipmentArray = if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment]
var serviceDetails = ({(flatten(shipmentArray) filter (getCustomAttDetail($."shipping-address", "addressType")== "SERVICE"))}) default null
var parentName = vars.parentProductName[0].parentName
var aemHandoverPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "aemHandoverPayload"))[0]."__text") default "{}"), "application/json")
var addressMatchType = if (!isEmpty((aemHandoverPayload filterObject (value, key) -> (key contains "baseDetails-") and (value.product[0].technology contains ("NBN"))))) ((aemHandoverPayload filterObject (value, key) -> (key contains "baseDetails-") and (value.product[0].technology contains ("NBN")))[0].planDetails.addressMatchType) else null
var sqPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "serviceQualification"))[0]."__text") default "{}"), "application/json")
var nbnLocationId = ((sqPayload filterObject ($$ contains("LOC"))) pluck ($$))[0]
var PlanBillingOfferId = getCustomAttDetail(rootElement,"planBillingOfferId") default ""
var gnafid = sqPayload."$(PlanBillingOfferId)" default ""
//var originalSqResult = if (!isEmpty(sqPayload)) sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service filter ((lower($.family) == "nbn fttp") or (lower($.family) == "nbn cable (hfc)")) else ""
var originalSqResult = if (!isEmpty(sqPayload)) sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service else ""
var originalSqResultFV = if (!isEmpty(sqPayload)) sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service else ""
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
var dsqDataRaw = getCustomAttDetail(rootElement, "dsqDetails")
var dsqDataJson = if (!isEmpty(dsqDataRaw)) read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='dsqDetails')).'__text'[0], "application/json") else null
var dsqSpeedDetailsId = dsqDataJson."$(PlanBillingOfferId)" default ""
var dsqSpeedDetails = if (!isEmpty(dsqDataJson)) dsqDataJson."$(dsqSpeedDetailsId)".dsqSpeedDetails else ""
var svcQualificationAddressOrigSq = (sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service filter ($.family ~= "Original SQ Result"))[0].serviceSpecCharacteristics.serviceSpecCharacteristics
//var svcQualificationAddressOrigSq = sqPayload."$(gnafid)".response.serviceCharacteristics
---
if ( networkTechnology ~= 'HWBB' )
{ 
	flowtype: vars.sfccOrderType,
	parentItems: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
	"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productOfferId')[0]."__text",
	"sfccProductType" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
    "parentName" : item."product-name"
	})) filter ($.sfccProductType[0] == "OFFER"),
    childItems: (((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
"itemId" : (item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'billingOfferId')[0]."__text",
	"sfccProductType" : (item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
    "productName" : item."bundled-product-lineitems"."bundled-product-lineitem"."product-name"
	})) filter (($.sfccProductType[0] != "OFFER" or $.sfccProductType[0] != "SIMPLE_PRODUCT") and $.itemId != null and $.productName != parentName)),
	simpleProducts: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
"itemId" : (item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productOfferId')[0]."__text",
	"sfccProductType" : (item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
	})) filter ($.sfccProductType[0] == "SIMPLE_PRODUCT") 
}
else
{
	flowtype:vars.sfccOrderType,
	parentItems: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
	"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'productOfferId')[0]."__text",
	"sfccProductType" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
    "parentName" : item."product-name",
    "contractDuration": vars.basePlanContractDuration.contractDuration
	})) filter ($.sfccProductType[0] == "OFFER"),

    childItems: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
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
	})) filter (($.sfccProductType[0] != "OFFER" or $.sfccProductType[0] != "SIMPLE_PRODUCT") and $.itemId != null and isEmpty($.isPromotionItem)))),
	
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
	})) filter (($.sfccProductType[0] != "OFFER" or $.sfccProductType[0] != "SIMPLE_PRODUCT") and $.itemId != null and !isEmpty($.isPromotionItem)))),
	
	simpleProducts: repeatItemsBasedOnQty(((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
    "itemId" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'productOfferId')[0]."__text",
	"sfccProductType" : (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'sfccProductType')."__text",
   "contractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text",
	"planContractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'planContractDuration')[0]."__text",
	//"installationMethod": if((flatten(rootElement.shipments.shipment."custom-attributes"."custom-attribute") filter $."@attribute-id"=="optusAppointmentRequired")[0]."__text" == "true") "Professional Install" else "SelfInstall"
	"addressMatchType": if(!isEmpty(addressMatchType == "EXACT_MATCH")) "Exact" else addressMatchType,
	"quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null
	})) filter ($.sfccProductType[0] == "SIMPLE_PRODUCT")),
	fixedBroadband: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
		"itemId": (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
    	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
    	"productType": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "productType"))[0]."__text",
    	"contractDuration": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "contractDuration"))[0]."__text",
    	"networkTechnology": (rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "technology"))[0]."__text",
    	"installationMethod": if((flatten(rootElement.shipments.shipment."custom-attributes"."custom-attribute") filter $."@attribute-id"=="optusAppointmentRequired")[0]."__text" ~= "true") "Professional Install" else "SelfInstall",
    	"addressMatchType": if(!isEmpty(addressMatchType == "EXACT_MATCH")) "Exact" else addressMatchType,
    	"chargeZone": if (networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."EIS PNSA CODE"[0][0] else "",
    	"cvcId": if (networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN CVC ID"[0][0] else "",
    	"gnafId": addressMatchType,
    	"nbnLocationId": (originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN LOCATION ID"[0][0]) default nbnLocationId,
    	"nbnDevChargeFlag": originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN DEV CHARGE FLAG"[0][0],
    	"nbnNtdId": if (networkTechnology =="NBN FTTP" or networkTechnology =="NBN Cable (HFC)")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD ID"[0][0] else "",
    	"nbnNtdLocationId": if (networkTechnology =="NBN FTTP" or networkTechnology =="NBN Cable (HFC)") capitalize(originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD LOCATION ID"[0][0]) else "",
    	//"nbnPortId": originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN PORT ID"[0][0],
    	"nbnPortId" : if (networkTechnology =="NBN FTTP" or networkTechnology =="NBN Cable (HFC)") if(!isEmpty(getCustomAttDetail(rootElement, "availablePort")) and getCustomAttDetail(rootElement, "orderType") == "ServiceTransfer" ) getCustomAttDetail(rootElement, "availablePort")[-1] else "" else "",
    	"nbnNtdType": if (networkTechnology =="NBN FTTP" or networkTechnology =="NBN Cable (HFC)") originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD TYPE"[0][0] else "",
    	"tesa": if (networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."TESA"[0][0] else "",
    	"New_line_consent_Flag_BCC": if (networkTechnology =="NBN FTTC" or networkTechnology =="NBN FTTB" or networkTechnology =="NBN FTTN")
    	                                 if((getCustomAttDetail(serviceDetails,'nbnInstallationCharge') == "true" ))"Yes" 
    	                                 else "No" 
    	                             else "",
    	"Copper_Pair_ID_BCC": if (networkTechnology =="NBN FTTC" or networkTechnology =="NBN FTTB" or networkTechnology =="NBN FTTN") 
    	                        if(!isEmpty(getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')))getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')
    		                    else if (!isEmpty(getCustomAttDetail(serviceDetails,'selectedLine')))(getCustomAttDetail(serviceDetails,'selectedLine') splitBy " - ")[1]
    		                    else "" 
    		                 else "",
    	//"Authority_Flag_BCC": if ((getCustomAttDetail(serviceDetails,'technology') contains "NBN")) "NotDetermined" else null,
    	"Authority_Flag_BCC": getCustomAttDetail(rootElement, "authorityFlag"),    	
    	("Maximum_Download_Speed": if(!isEmpty(dsqSpeedDetails.NBN_TC4_DOWNSTREAM_CURRENT_ASSURED_RATE) and !isEmpty(dsqSpeedDetails.NBN_TC4_UPSTREAM_CURRENT_ASSURED_RATE)) 
	        if(!isEmpty(dsqSpeedDetails.NBN_VDSL_MAX_UPSTREAM_SPEED) and !isEmpty(svcQualificationAddressOrigSq.'NBN VDSL MAX UPSTREAM SPEED UNIT OF MEASURE'[0]))
	        	(dsqSpeedDetails.NBN_VDSL_MAX_UPSTREAM_SPEED ++ " " ++ svcQualificationAddressOrigSq.'NBN VDSL MAX UPSTREAM SPEED UNIT OF MEASURE'[0])
	        else if (!isEmpty(dsqSpeedDetails.NBN_VDSL_MAX_UPSTREAM_SPEED) and isEmpty(svcQualificationAddressOrigSq.'NBN VDSL MAX UPSTREAM SPEED UNIT OF MEASURE'[0]))
				(dsqSpeedDetails.NBN_VDSL_MAX_UPSTREAM_SPEED ++ " " ++ "MBPS")
	        else null
        else null) if (!isEmpty(dsqSpeedDetails)),
        ("Maximum_Upload_Speed": if(!isEmpty(dsqSpeedDetails.NBN_TC4_DOWNSTREAM_CURRENT_ASSURED_RATE) and !isEmpty(dsqSpeedDetails.NBN_TC4_UPSTREAM_CURRENT_ASSURED_RATE)) 
	        if(!isEmpty(dsqSpeedDetails.NBN_VDSL_MAX_DOWNSTREAM_SPEED) and !isEmpty(svcQualificationAddressOrigSq.'NBN VDSL MAX DOWNSTREAM SPEED UNIT OF MEASURE'[0]))
	        	(dsqSpeedDetails.NBN_VDSL_MAX_DOWNSTREAM_SPEED ++ " " ++ svcQualificationAddressOrigSq.'NBN VDSL MAX DOWNSTREAM SPEED UNIT OF MEASURE'[0])
	        else if (!isEmpty(dsqSpeedDetails.NBN_VDSL_MAX_DOWNSTREAM_SPEED) and isEmpty(svcQualificationAddressOrigSq.'NBN VDSL MAX DOWNSTREAM SPEED UNIT OF MEASURE'[0]))
				(dsqSpeedDetails.NBN_VDSL_MAX_DOWNSTREAM_SPEED ++ " " ++ "MBPS")
	        else null
        else null) if (!isEmpty(dsqSpeedDetails))
        
	})) filter ($.itemId != null and $.isBasePlan ~= "true" and $.productType ~= "Fixed Broadband"),
	
	fixedVoice: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
        "itemId": (convertObjectToArray(item."bundled-product-lineitems"."bundled-product-lineitem"."custom-attributes"."custom-attribute") filter $."@attribute-id" == 'billingOfferId')[0]."__text",
    	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
    	"productType": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "productType"))[0]."__text",
    	//"CSGWaiverConsentFlag": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "CSGWaiverConsentFlag"))[0]."__text",
    	"CSGWaiverConsentFlag": getCustomAttDetail(rootElement, "CSGWaiverConsentFlag") default null,
    	"chargeZone": originalSqResultFV.serviceSpecCharacteristics.serviceSpecCharacteristics."EIS PNSA CODE"[0][0],
    	"nbnLocationId": originalSqResultFV.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN LOCATION ID"[0][0],
    	"tesa": originalSqResultFV.serviceSpecCharacteristics.serviceSpecCharacteristics."TESA"[0][0],
    	"cvcId": originalSqResultFV.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN CVC ID"[0][0],
    	"existingChargeZone": getCustomAttDetail(rootElement, "relocationOldChargeZone") default "",
    	"Copper_Pair_ID_BCC": if(!isEmpty(getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')))getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')
    		                  else if (!isEmpty(getCustomAttDetail(serviceDetails,'selectedLine')))(getCustomAttDetail(serviceDetails,'selectedLine') splitBy " - ")[1]
    		                  else null,
        "ExistingServiceIDPhone": getCustomAttDetail(rootElement, "phoneLineHomeNumber") default ""        	   
        	    	
	})) filter ($.itemId != null and $.isBasePlan ~= "true" and $.productType ~= "Fixed Voice"),
	"fixedVoicePortability": {
		"existingCarrierAcctNo": getCustomAttDetail(rootElement, "phoneLineAccountNumber"),
		"donorCarrier": numberPortabilityCheckResponse.donorCarrier,
		"existingPhoneNo": getCustomAttDetail(rootElement, "phoneLineHomeNumber"),
		"currentCarrier": numberPortabilityCheckResponse.currentCarrier,
		"sfccOrderDate": rootElement.'order-date',
		"phoneLineTransferNumber": getCustomAttDetail(rootElement, "phoneLineTransferNumber"),
		"flowType": getCustomAttDetail(rootElement, "flowType")
	}
}