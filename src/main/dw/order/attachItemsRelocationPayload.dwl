%dw 2.0
import * from dw::core::Strings
output application/json
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var shipmentArray = if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment]
var serviceDetails = ({(flatten(shipmentArray) filter (getCustomAttDetail($."shipping-address", "addressType")== "SERVICE"))}) default null
var parentName = vars.parentProductName[0].parentName
var aemHandoverPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "aemHandoverPayload"))[0]."__text") default "{}"), "application/json")
var sqPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "serviceQualification"))[0]."__text") default "{}"), "application/json")
//var originalSqResult = (sqPayload[1].response.checkServiceCoverageResponse.services.service filter ($.name ~= "SQ Result"))[0]
var originalSqResult = (sqPayload..response[0].checkServiceCoverageResponse.services.service filter ($.name ~= "SQ Result"))[0]
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
var PlanBillingOfferId = getCustomAttDetail(rootElement,"planBillingOfferId") default ""
var gnafid = sqPayload."$(PlanBillingOfferId)" default ""
var dsqDataRaw = getCustomAttDetail(rootElement, "dsqDetails")
var dsqDataJson = if (!isEmpty(dsqDataRaw)) read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='dsqDetails')).'__text'[0], "application/json") else null
var dsqSpeedDetailsId = dsqDataJson."$(PlanBillingOfferId)" default ""
var dsqSpeedDetails = if (!isEmpty(dsqDataJson)) dsqDataJson."$(dsqSpeedDetailsId)".dsqSpeedDetails else ""
//var svcQualificationAddressOrigSq = (sqPayload."$(gnafid)".response.checkServiceCoverageResponse.services.service filter ($.family ~= "Original SQ Result"))[0].serviceSpecCharacteristics.serviceSpecCharacteristics
var svcQualificationAddressOrigSq = sqPayload."$(gnafid)".response.serviceCharacteristics
---
{
	flowtype:vars.sfccOrderType,
	parentItems: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
	//"itemId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'relocationOfferingId')[0]."__text",
	//"itemId" : "34740624",
	"sfccProductType" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'sfccProductType')."__text",
    "parentName" : item."product-name",
    "contractDuration": vars.basePlanContractDuration.contractDuration,
    "jarvisInstanceId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'relocationOfferingId')[0]."__text",
    "offerInstanceId" : (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'relocationOfferingInstanceId')[0]."__text",
	})) filter ($.sfccProductType[0] == "OFFER"),
	
	
	 childItems: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
    //"itemId" :  read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").offeringInstanceId,
    "productOfferId": read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").offeringId,
    "jarvisInstanceId": read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").id,
    "offerInstanceId" : read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").offeringInstanceId,
    "vlocityProductCode" : (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "vlocityProductCode"))[0]."__text",
    "serviceType":  read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").serviceType,
    "lob": read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").lob,
    //"productName" : item."bundled-product-lineitems"."bundled-product-lineitem"."product-name",
    "contractDuration": (item."custom-attributes"."custom-attribute" filter $."@attribute-id" == 'contractDuration')[0]."__text",
    "quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null
	})) filter (($.vlocityProductCode != null)))),
	//filter (($.vlocityProductCode != null and $.serviceType !="Fixed Broadband" and $.serviceType !="Fixed Voice")))),
	
	billingOfferItems: repeatItemsBasedOnQty((((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
      "productName" : item."product-name",
      "contractDuration": (item."custom-attributes"."custom-attribute" filter ( $."@attribute-id" == 'planContractDuration'))[0]."__text",
      "quantity": if (!isEmpty(item.quantity."__text")) item.quantity."__text" as Number else null,
      "vlocityProductCode" : (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "vlocityProductCode"))[0]."__text",
      "sfccProductType" : (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" == 'sfccProductType'))[0]."__text"
     })) filter (($.vlocityProductCode == null and $.sfccProductType =="COMPONENT_BILLING_OFFER")))),		 
	
	fixedBroadband: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
		//"itemId": "8558784",
        "vlocityProductCode" : (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "vlocityProductCode"))[0]."__text",
        "serviceType":  read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").serviceType,
    	"isBasePlan": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "isBasePlan"))[0]."__text",
    	"productType": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "productType"))[0]."__text",
    	"contractDuration": (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "contractDuration"))[0]."__text",
    	//"networkTechnology": (rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "technology"))[0]."__text",
    	"networkTechnology": read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology,
    	"installationMethod": if((flatten(rootElement.shipments.shipment."custom-attributes"."custom-attribute") filter $."@attribute-id"=="optusAppointmentRequired")[0]."__text" ~= "true") "Professional Install" else "SelfInstall",
    	//"addressMatchType": aemHandoverPayload[1].planDetails.addressMatchType,
    	"addressMatchType": aemHandoverPayload..planDetails[0].addressMatchType,
    	"chargeZone": if (read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."EIS PNSA CODE"[0]else "",
    	"cvcId": if (read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN CVC ID"[0] else "",
    	//"gnafId": aemHandoverPayload[1].planDetails.addressMatchType,
        "gnafId": aemHandoverPayload..planDetails[0].addressMatchType,
    	"nbnLocationId": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		                 or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)")
    		                 and vars.sfccOrderType =="RelocationOnline")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN LOCATION ID"[0] 
    		             else "",
    	"nbnDevChargeFlag": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		                 or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)")
    		                 and vars.sfccOrderType =="RelocationOnline")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN DEV CHARGE FLAG"[0] 
    		             else "",
    	"nbnNtdId": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		              or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)") 
    		              and vars.sfccOrderType =="RelocationOnline")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD ID"[0]
    		        else "",
    	"nbnNtdLocationId": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		                   or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)")
    		                   and vars.sfccOrderType =="RelocationOnline")capitalize(originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD LOCATION ID"[0])
    		                else "",
    	"nbnPortId": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		            or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)") 
    		            and vars.sfccOrderType =="RelocationOnline")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN PORT ID"[0] 
    		         else "",
    	"nbnNtdType": if ((read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN FTTP" 
    		            or read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology =="NBN Cable (HFC)") 
    		            and vars.sfccOrderType =="RelocationOnline")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD TYPE"[0] 
    		          else "",
    	"tesa": if (read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").networkTechnology !="5G")originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."TESA"[0] else "",
    	//"New_line_consent_Flag_BCC": if((getCustomAttDetail(serviceDetails,'nbnInstallationCharge') == "true" ))"Yes" else "No",
    	"New_line_consent_Flag_BCC": "",
    	"Copper_Pair_ID_BCC": "",
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
        else null) if (!isEmpty(dsqSpeedDetails)),
    	"BYODSelected": getCustomAttDetail(rootElement, "BYODSelected")
	})) filter (($.vlocityProductCode != null and $.serviceType ~="Fixed Broadband")),
	
	fixedVoice: ((rootElement."product-lineitems"."product-lineitem") map (item, index) -> ({
		//"itemId": "8424064",
        "vlocityProductCode" : (item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "vlocityProductCode"))[0]."__text",
        "serviceType":  read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").serviceType,
        "cvcId": originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN CVC ID"[0],
    	"chargeZone": getCustomAttDetail(rootElement, "relocationNewChargeZone") default "",
    	"existingChargeZone": getCustomAttDetail(rootElement, "relocationOldChargeZone") default "",
    	"nbnLocationId": capitalize(originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."NBN NTD LOCATION ID"[0]),
    	"tesa": originalSqResult.serviceSpecCharacteristics.serviceSpecCharacteristics."TESA"[0],
    	"ExistingServiceIDPhone": read((((item."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "relocationProductData"))[0]."__text") default "{}"), "application/json").serviceId,
    	//"Copper_Pair_ID_BCC": (getCustomAttDetail(serviceDetails,'selectedLine') splitBy " - ")[1] default null
    	"Copper_Pair_ID_BCC": if(!isEmpty(getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')))getCustomAttDetail(serviceDetails,'selectedLineCopperPairId')
    		                  else if (!isEmpty(getCustomAttDetail(serviceDetails,'selectedLine')))(getCustomAttDetail(serviceDetails,'selectedLine') splitBy " - ")[1]
    		                  else null
    		                     	
	})) filter (($.vlocityProductCode != null and $.serviceType ~="Fixed Voice"))	
}