%dw 2.0
import * from dw::core::Strings
output application/json skipNullOn="everywhere"
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
var calculatedTotalsDeviceCost= read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='calculatedTotals')).'__text'[0], "application/json")
var deviceCost = if(isEmpty(calculatedTotalsDeviceCost.DEVICE_COST_VALUE)) 0 else calculatedTotalsDeviceCost.DEVICE_COST_VALUE  as Number
var creditCheckResp = (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='creditCheckResponse')).'__text'[0]
var shipmentArray = if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment]
var customerguestval = rootElement.customer.guest
var payment = if(rootElement.payments.payment is Array) rootElement.payments.payment else [rootElement.payments.payment]
var creditCheckRespNullChecker = if(!isEmpty(creditCheckResp)) read(creditCheckResp,"application/json") else null
var tech = (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='technology')).'__text'[0]
var maxRecur = creditCheckRespNullChecker.creditResponse[0].conditionalOffer.MaxRecurringCost
var maxEquip = creditCheckRespNullChecker.creditResponse[0].conditionalOffer.MaxEquipmentCost 

//var decCategory = creditCheckRespNullChecker.creditResponse[0].decisionCategory 
var decCategory = if (vars.sfccOrderType == "RelocationOnline") getCustomAttDetail(rootElement,"decisionCategory")
                  else creditCheckRespNullChecker.creditResponse[0].decisionCategory 
var textMess = creditCheckRespNullChecker.creditResponse[0].freeTextMessage
var secCol = creditCheckRespNullChecker.creditResponse[0].secureCollect

var accountType = (getCustomAttDetail(rootElement, "accountType") default "" ) replace "Account" with ""

var primaryIDUniquenessRes = do{
	var rawprimaryiduniquenessresponse = (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='primaryIDUniquenessResponse')).'__text'[0]
	var primaryIDUniquenessResponseNullChecker = if(!isEmpty(rawprimaryiduniquenessresponse)) read(rawprimaryiduniquenessresponse,"application/json") else null
	---
	primaryIDUniquenessResponseNullChecker
} 
var secondaryIDUniquenessRes = do{
	var rawsecondaryiduniquenessresponse = (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='secondaryIDUniquenessResponse')).'__text'[0]
	var secondaryIDUniquenessResponseNullChecker = if(!isEmpty(rawsecondaryiduniquenessresponse)) read(rawsecondaryiduniquenessresponse,"application/json") else null
	---
	secondaryIDUniquenessResponseNullChecker
}
var primaryIdCheckRes = do{
	var rawprimaryIdCheckresponse = (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='primaryIDCheckResponse')).'__text'[0]
	var primaryIdCheckResponseNullChecker = if(!isEmpty(rawprimaryIdCheckresponse)) read(rawprimaryIdCheckresponse,"application/json") else null
	---
	primaryIdCheckResponseNullChecker
} 
var secondaryIdCheckRes = do{
	var rawsecondaryIdCheckresponse = (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='secondaryIDCheckResponse')).'__text'[0]
	var secondaryIdCheckResponseNullChecker = if(!isEmpty(rawsecondaryIdCheckresponse)) read(rawsecondaryIdCheckresponse,"application/json") else null
	---
	secondaryIdCheckResponseNullChecker
}

var mcIDDetailsResp = do {
	var mcIDCustomAttrib = getCustomAttDetail(rootElement, "mcIDDetailsResponse")
	fun isMCIDCustomAttribNotNull() = if(mcIDCustomAttrib != null) true else false
	---
	if(isMCIDCustomAttribNotNull())
		read(mcIDCustomAttrib,"application/json")
	else 
		null
}
---
{
    effectiveDate: rootElement.'order-date',
    Vlocity_Status__c: 'Draft',
    status:'Draft',
    Name:   rootElement.'original-order-no',
    OrderReferenceNumber:   rootElement.'original-order-no',
    createdByAPI: true,
	Network_Technology__c: (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='technology')).'__text'[0],
	Type: if (((shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'newFixed' or (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'new' or (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'mobile') and (customerguestval == "true" or getCustomAttDetail(rootElement, "isContactOnly") == "true" or getCustomAttDetail(rootElement, "isSecondaryContact") == "true") and isEmpty(vars.mobileProductOfferAttrbs.parentItems[0].transactionType[0]) ) 'New_New' 
          else if (((shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'newFixed' or (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'new' or (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'mobile') and (customerguestval == "false") and isEmpty(vars.mobileProductOfferAttrbs.parentItems[0].transactionType[0]) ) 'New_Existing'
          else if (((shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0] == 'mobile') and ((vars.mobileProductOfferAttrbs.parentItems[0].transactionType[0]) == "RECON")) 'Recontract'
          else (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='baseOrderType')).'__text'[0],
 	Flow_Type__c: capitalize((shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='flowType')).'__text'[0]),
 	//Flow_Type__c: capitalize(getCustomAttDetail(rootElement, "flowType")),
 	Item_Category_Type__c: (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='itemCategoryType')).'__text'[0],
	TRS_APP_NUMBER__c: (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='creditCheckTrsApplicationNumber')).'__text'[0],
	Credit_Check_Status__c: decCategory default null,
	//Max_Recurring_Cost__c: if (!isEmpty(maxRecur)) maxRecur else "0.00",
    //Max_Equipment_Cost__c: if (!isEmpty(maxEquip)) maxEquip else "0.00",
    Max_Recurring_Cost__c: if (!isEmpty(maxRecur)) (if(maxRecur is Array) maxRecur[0] else maxRecur) else "0.00",
    Max_Equipment_Cost__c: if (!isEmpty(maxEquip)) (if (maxEquip is Array) maxEquip[0] else maxEquip) else "0.00",
	Credit_Limit_Check_Required__c: true,
    Credit_Check_Text_Message__c: if (!isEmpty(textMess)) (textMess as String replace "\n" with "") replace "\r" with "" else null,
	Credit_Check_Response__c: (creditCheckRespNullChecker.inteflowResponseXML as String replace "\n" with "") default null,
	Credit_Check_Secure_Collect__c: secCol default null,
    Credit_Check_Response_Update_Date_Time__c: (creditCheckRespNullChecker.transactionResponseDateTime as DateTime) as String {format: "yyyy-MM-dd H:mm:ss"} default null,
 	ID_Check_Status__c: (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='IdCheckStatus')).'__text'[0],
 	Individual_Reference_Number__c: (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='individualReferenceNumber')).'__text'[0],
	SFCC_Total_Price__c: rootElement.totals."order-total"."gross-price" as Number,
	vlocity_cmt__NumberOfContractedMonths__c:(shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='planContractDuration')).'__text'[0] as Number,
	Device_Cost_in_SFCC__c: deviceCost,
	vlocity_cmt__DeliveryMethod__c: (shipmentArray filter $."shipping-method" == "Deliver to customer")[0],
	"installationMethod": if((flatten(shipmentArray."custom-attributes"."custom-attribute") filter $."@attribute-id"=="optusAppointmentRequired")[0]."__text" == "true") "Professional Install" else "SelfInstall",
	Create_New_Billing_Account__c: (rootElement.'custom-attributes'.'custom-attribute' filter ($."@attribute-id" == "createNewBillingAccount"))[0]."__text",
	//("serviceRequestDate": (rootElement.'custom-attributes'.'custom-attribute' filter ($."@attribute-id" == "formattedServiceRequestDate"))[0]."__text" as LocalDateTime { format: "dd/MM/yyyy HH:mm"} as String {format: "yyyy-MM-dd'T'HH:mm:ss.SSS"} ++ "+0000") if (!isEmpty((rootElement.'custom-attributes'.'custom-attribute' filter ($."@attribute-id" == "formattedServiceRequestDate"))[0])),
	"serviceRequestDate": (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='serviceRequestDate')).'__text'[0],
	"cardHolder": rootElement.payments.payment."credit-card"."card-holder",
	"cardNumber": (rootElement.payments.payment."credit-card"."card-number" splitBy "-")[3] default null,
	"cardType": rootElement.payments.payment."credit-card"."card-type",
	"cardExpirationMonth": if (payment."custom-method"."method-name"[0] == "PAYMEANS_CREDIT_CARD") (getCustomAttDetail(payment."custom-method"[0],"cardExpiryMonth") as Number) 
                           else if(!isEmpty(rootElement.payments.payment."credit-card"."expiration-month")) (rootElement.payments.payment."credit-card"."expiration-month" as Number) else null,
	"cardExpirationYear": if (payment."custom-method"."method-name"[0] == "PAYMEANS_CREDIT_CARD") (getCustomAttDetail(payment."custom-method"[0],"cardExpiryYear") as Number)
                           else if(!isEmpty(rootElement.payments.payment."credit-card"."expiration-year")) (rootElement.payments.payment."credit-card"."expiration-year" as Number) else null,
	"cardToken": if (payment."custom-method"."method-name"[0] == "PAYMEANS_CREDIT_CARD") getCustomAttDetail(payment."custom-method"[0],"cardToken")   
                 else rootElement.payments.payment."credit-card"."card-token",
    "payMeansID": if (payment."custom-method"."method-name"[0] == "PAYMEANS_CREDIT_CARD") getCustomAttDetail(payment."custom-method"[0],"payMeansId")   
                  else null,
	"deliveryDate": (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='deliveryDate')).'__text'[0],
	"residentialTimezoneOffsetExisting": getCustomAttDetail(rootElement,"timeZoneOffset") default null,    	
	//Customer_Has_NCD__c: (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='hasNCDAtPremises')).'__text'[0]
	SFCCncdRequired: (shipmentArray[0].'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='ncdRequired')).'__text'[0],
	SubscriptionOrder_Scenario:(rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "subscriptionOrderType"))[0]."__text" default "NA",
	Two_Factor_Authenticated__c: getCustomAttDetail(rootElement, "twoFactorAuthenticated") as Boolean default null,
	Credit_Check_Type__c: creditCheckRespNullChecker.idCheckIndicator default null,
	SM_Session_Id__c: (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='smSessionId')).'__text'[0],	
	Primary_Id_Uniqueness_Action__c:
		// DOP-3345
		if (accountType == "Shell")
			(
				if (primaryIDUniquenessRes !=null)
					(primaryIDUniquenessRes.ImpValidateContactPersonDetailsOutput.implContactPersonDetailsStatus.implContactPersonDetails filter ((item)->item.primaryIdIndicator == true))[0].action
				else 
					(secondaryIDUniquenessRes.ImpValidateContactPersonDetailsOutput.implContactPersonDetailsStatus.implContactPersonDetails filter ((item)->item.primaryIdIndicator == true))[0].action
			)
		else if (accountType == "Mature")
			(
				if (primaryIDUniquenessRes != null)
					(primaryIDUniquenessRes.ImpValidateContactPersonDetailsOutput.implContactPersonDetailsStatus.implContactPersonDetails filter ((item)->item.primaryIdIndicator == true))[0].action
				else if (secondaryIDUniquenessRes != null)
					(secondaryIDUniquenessRes.ImpValidateContactPersonDetailsOutput.implContactPersonDetailsStatus.implContactPersonDetails filter ((item)->item.primaryIdIndicator == true))[0].action
				else if (primaryIdCheckRes == null and secondaryIdCheckRes == null)
					//ID is not captured from SFCC, whether the ID uniqueness CR is active or not
					"No ID"
				else
					//ID is captured from SFCC
					null
			)
		else 
			null,
  Secondary_Id_Uniqueness_Action__c: (secondaryIDUniquenessRes.ImpValidateContactPersonDetailsOutput.implContactPersonDetailsStatus.implContactPersonDetails filter ((item)->item.primaryIdIndicator == false))[0].action,
	"Source__c": mcIDDetailsResp.source,
	"Verified_At__c": mcIDDetailsResp.verified_at as LocalDateTime default null,
	"XML_Token__c": (mcIDDetailsResp.dynamicAttributes filter ((item, index) -> lower(item.name) == "xml token"))[0].value default null,
	"optusafeUploadId__c": mcIDDetailsResp.optusafeUploadId,
	"Authority_Flag_BCC": getCustomAttDetail(rootElement, "authorityFlag")
}