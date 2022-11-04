%dw 2.0
output application/json skipNullOn="everywhere"
import * from dw::core::Arrays
import * from dw::core::Strings
import changeSreetTypeToCode, countryCodeToText, changeSubAddressTypeTextToCode, getTimeZone, getFlowTypeReason from customFunctionModule::customFunctions
var rootElement = if (payload.orders != null) payload.orders.order else payload.order
fun whichPassport(primaryField, secondaryField) = (
    if(
        (getCustomAttDetail(rootElement, "primaryIDType") == "AU_PASSPORT") or
        (getCustomAttDetail(rootElement, "primaryIDType") == "NZ_PASSPORT") or
        (getCustomAttDetail(rootElement, "primaryIDType") == "INTERNATIONAL_PASSPORT")
    ) 
        primaryField 
    else (secondaryField))
fun removeEmptyObjects(obj) = obj mapObject (
if(isEmpty($)) (($$):$) - $$
else if ( (typeOf($) as String) == "Object")
($$):removeEmptyObjects(($))
else if ( (typeOf($) as String) == "Array")
(($$): helperFunction($))
else ($$): $
)
fun helperFunction(array) = array map (
if((typeOf($) as String) == "Object")
removeEmptyObjects($)
else if((typeOf($) as String) == "Array")
helperFunction($)
else 
$
)
fun personalIdTypeCond(str) = (
    if(str == "DRIVER_LICENCE") "Driving Licence"
    else if((str == "AU_PASSPORT") or (str == "NZ_PASSPORT")) "Passport"
    else if(str == "INTERNATIONAL_PASSPORT") "Overseas Passport"
    else str)
fun passportCountrCond(str) = (
    if(str == "AU_PASSPORT") "AUSTRALIA"
    else if(str == "NZ_PASSPORT") "NEW ZEALAND"
    else str)
fun secondaryTypeIdCond(str)= (
    if((str == "AU_PASSPORT") or (str == "NZ_PASSPORT")) "Passport"
    else if(str == "DRIVER_LICENCE") "Driving Licence"
    else if(str == "INTERNATIONAL_PASSPORT") "Overseas Passport"
    else str)
fun subAddressCond(level, priorityValue, value) = (
    getCustomAttDetail(level, priorityValue) default getCustomAttDetail(level, value)
)

// Function to get custom-attribute value
fun getCustomAttDetail(arr, str) =  (arr."custom-attributes"."custom-attribute" filter ($."@attribute-id" == str))[0]."__text"

fun getStreetOrBuildingNumber(streetNumber, buildingNumber) = 
    if(!isEmpty(buildingNumber) and isEmpty(streetNumber))
        buildingNumber
    else if(!isEmpty(streetNumber)  and isEmpty(buildingNumber)) 
        streetNumber
    else if(!isEmpty(streetNumber)  and !isEmpty(buildingNumber)) 
        streetNumber
    else ""
/////////////////////////////////////////// ADDRESS RELATED VARIABLE AND FUNCTIONS

var shipmentArray = if(rootElement.shipments.shipment is Array) rootElement.shipments.shipment else [rootElement.shipments.shipment]
// Variable for address rootElements
var installationAddress = (shipmentArray filter $."shipping-method" == "Not Applicable")[0]
var address = (shipmentArray filter $."shipping-method" == "Deliver to customer")[0]
var billAddress = rootElement.customer."billing-address"
var payment = if(rootElement.payments.payment is Array) rootElement.payments.payment else [rootElement.payments.payment]
var sQData = getCustomAttDetail(rootElement, "serviceQualification")
var dsqDataRaw = getCustomAttDetail(rootElement, "dsqDetails")
var serviceQualification = if (!isEmpty(sQData)) read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='serviceQualification')).'__text'[0], "application/json") else null
var dsqDataJson = if (!isEmpty(dsqDataRaw)) read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='dsqDetails')).'__text'[0], "application/json") else null
var PlanBillingOfferId = getCustomAttDetail(rootElement,"planBillingOfferId") default ""
var gnafid = serviceQualification."$(PlanBillingOfferId)" default ""
var dsqSpeedDetailsId = dsqDataJson."$(PlanBillingOfferId)" default ""
var dsqSpeedDetails = if (!isEmpty(dsqDataJson)) dsqDataJson."$(dsqSpeedDetailsId)".dsqSpeedDetails else ""
var svcQualificationAddress= if (!isEmpty(serviceQualification)) serviceQualification."$(gnafid)".request else ""
var svcQualificationAddressResp = if (!isEmpty(serviceQualification)) serviceQualification."$(gnafid)".response else ""
var svcQualificationAddressOrigSq = (svcQualificationAddressResp.checkServiceCoverageResponse.services.service filter ($.family ~= "Original SQ Result"))[0].serviceSpecCharacteristics.serviceSpecCharacteristics
var relocationFlowType = if (getCustomAttDetail(rootElement, "baseOrderType") == "relocation" and getCustomAttDetail(rootElement, "flowType") == "OFFLINE") "RelocationOffline" 
else if (getCustomAttDetail(rootElement, "baseOrderType") == "relocation" and getCustomAttDetail(rootElement, "flowType") == "ONLINE") "RelocationOnline" 
else "non_Relocation"
var readrelocationPayload  = if (relocationFlowType == "RelocationOffline" or relocationFlowType == "RelocationOnline") read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='relocationPayload')).'__text'[0], "application/json") else null
var relocationOfflineResdAddr= if (!isEmpty(readrelocationPayload))readrelocationPayload.ServiceQualification.request else ""
var ifExistsreadrelocationServiceData = getCustomAttDetail(rootElement,"relocationServiceData") //vh
var readrelocationServiceData = if ((relocationFlowType == "RelocationOffline" or relocationFlowType == "RelocationOnline") and !isEmpty(ifExistsreadrelocationServiceData)) read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='relocationServiceData')).'__text'[0], "application/json") else null
var readrelocationServiceDataJson = read((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='relocationServiceData')).'__text'[0], "application/json") default null
var relocationOfflinePrevResdAddr= if (!isEmpty(readrelocationServiceData))readrelocationServiceData else ""
var relocationNCDRequired = getCustomAttDetail(rootElement,"ncdRequired") default "false"
var prdType =((rootElement."product-lineitems"."product-lineitem") map (item, index) ->
({
    "ProductType" : (if((getCustomAttDetail(item,"productType") =="Fixed Broadband") )"FB"
    else if((getCustomAttDetail(item,"productType") =="Fixed Voice") )"FV"
     else "")
 }))filter($."ProductType" !="") reduce ($)
 var customerguestval = rootElement.customer.guest
//Variable for address UUID
var installationAddressUUID = getCustomAttDetail(installationAddress."shipping-address", "addressUUID") default ""
var residentialAddressUUID = getCustomAttDetail(rootElement, "residentialAddressUUID") default "" 
var deliveryAddressUUID = getCustomAttDetail(address."shipping-address", "addressUUID") default ""
var billAddressUUID = getCustomAttDetail(billAddress, "addressUUID") default ""
var sqPayload = read((((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "serviceQualification"))[0]."__text") default "{}"), "application/json")
var nbnLocationId = ((sqPayload filterObject ($$ contains("LOC"))) pluck ($$))[0]
//var originalSqResult = (sqPayload[1].response.checkServiceCoverageResponse.services.service filter ((lower($.family) == "nbn fttp") or (lower($.family) == "nbn cable (hfc)")))[0]
//Address Unit Numbers
var installationAddressUnitNumber = 
		if(!isEmpty(getCustomAttDetail(installationAddress."shipping-address", "manualAddressType")))
              getCustomAttDetail(installationAddress."shipping-address", "unitNumber")
        else getCustomAttDetail(installationAddress."shipping-address", "subAddressNumber")
var shippingAddressUnitNumber = 
		if(!isEmpty(getCustomAttDetail(address."shipping-address", "manualAddressType")))
              getCustomAttDetail(address."shipping-address", "unitNumber")
        else getCustomAttDetail(address."shipping-address", "subAddressNumber")
var previousAddressUnitNumber = if(!isEmpty(getCustomAttDetail(rootElement, "previousResidentialAddressType")))
            getCustomAttDetail(rootElement, "previousResidentialUnitNumber")
        else getCustomAttDetail(rootElement, "previousResidentialSubAddressNumber")
var billingAddressUnitNumber = if(!isEmpty(getCustomAttDetail(billAddress, "manualAddressType")))
            getCustomAttDetail(billAddress, "unitNumber")
        else getCustomAttDetail(billAddress, "subAddressNumber")
var residentialAddressUnitNumber = if(!isEmpty(getCustomAttDetail(rootElement, "residentialAddressType")))
            getCustomAttDetail(rootElement, "residentialUnitNumber")
        else getCustomAttDetail(rootElement, "residentialSubAddressNumber")
var svcQualificationAddressUnitNumber = if(!isEmpty(svcQualificationAddress))
                            (svcQualificationAddress.selectedAddress.implPhysicalAddress.unitNumber
                        	default svcQualificationAddress.selectedAddress.implPhysicalAddress.subAddressNumber default "")
                            else ""
                            
var selectedOrganizationDetailsString = (rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "selectedOrganizationDetails"))[0]."__text"
var selectedOrganizationDetails = if (!isEmpty(selectedOrganizationDetailsString)) read(selectedOrganizationDetailsString, "application/json") else null

// Set streetNumber fields for billing and shipping       
var installationAddressStreetNumber = 
    if(!isEmpty(getCustomAttDetail(installationAddress."shipping-address", "buildingNumber")) and isEmpty(getCustomAttDetail(installationAddress."shipping-address", "streetNumber")))
        "buildingNumber"
    else if(!isEmpty(getCustomAttDetail(installationAddress."shipping-address", "streetNumber"))  and isEmpty(getCustomAttDetail(installationAddress."shipping-address", "buildingNumber"))) 
        "streetNumber"
    else if(!isEmpty(getCustomAttDetail(installationAddress."shipping-address", "streetNumber"))  and !isEmpty(getCustomAttDetail(installationAddress."shipping-address", "buildingNumber"))) 
        "streetNumber"
    else ""
var billingAddressStreetNumber = 
    if(!isEmpty(getCustomAttDetail(billAddress, "buildingNumber")) and isEmpty(getCustomAttDetail(billAddress, "streetNumber")))
        "buildingNumber"
    else if(!isEmpty(getCustomAttDetail(billAddress, "streetNumber"))  and isEmpty(getCustomAttDetail(billAddress, "buildingNumber"))) 
        "streetNumber"
    else if(!isEmpty(getCustomAttDetail(billAddress, "streetNumber"))  and !isEmpty(getCustomAttDetail(billAddress, "buildingNumber")))
    	"streetNumber"
    else ""
var shippingAddressStreetNumber = 
    if(!isEmpty(getCustomAttDetail(address."shipping-address", "buildingNumber")) and isEmpty(getCustomAttDetail(address."shipping-address", "streetNumber")))
        "buildingNumber"
    else if(!isEmpty(getCustomAttDetail(address."shipping-address", "streetNumber"))  and isEmpty(getCustomAttDetail(address."shipping-address", "buildingNumber"))) 
        "streetNumber"
    else if(!isEmpty(getCustomAttDetail(address."shipping-address", "streetNumber"))  and !isEmpty(getCustomAttDetail(address."shipping-address", "buildingNumber"))) 
        "streetNumber"
    else ""  
    
// Function to add address fields which makes the address name                    
fun generateAddressName(buildingName, unitNumber, streetNumber, streetName, streetType, city, state, postcode)=
    if(!isEmpty(unitNumber))
        trim(
            (if(!isEmpty(buildingName)) buildingName ++ ", " else "") ++ 
            unitNumber ++ "/" ++ 
            (if(!isEmpty(streetNumber)) streetNumber ++ " " else "") ++ 
            (if(!isEmpty(streetName)) streetName ++ " " else "") ++ 
            (if(!isEmpty(streetType)) streetType else "") ++  
            (if(!isEmpty(city))  (if(!isEmpty(streetType)) ", " else "") ++ city else "") ++ 
            (if(!isEmpty(state)) (if(!isEmpty(city)) ", " else "") ++ state else "") ++
            (if(!isEmpty(postcode)) (if(!isEmpty(state)) ", " else "") ++ postcode else "")
        )
    else 
        trim(
            (if(!isEmpty(buildingName)) buildingName ++ ", " else "") ++ 
            (if(!isEmpty(streetNumber)) streetNumber ++ " " else "") ++ 
            (if(!isEmpty(streetName)) streetName ++ " " else "") ++ 
            (if(!isEmpty(streetType)) streetType else "") ++  
            (if(!isEmpty(city))  (if(!isEmpty(streetType)) ", " else "") ++ city else "") ++ 
            (if(!isEmpty(state)) (if(!isEmpty(city)) ", " else "") ++ state else "") ++
            (if(!isEmpty(postcode)) (if(!isEmpty(state)) ", " else "") ++ postcode else "")
        )
        
// Logic for splitting street name and number
fun splitStreetNameAndNum(address) =
    // 1. Check if, when the whole address is split, it only contains 2 nodes.
    // Directly split the address by <space> 
    if (((address splitBy(" ")) countBy((!isEmpty($)))) == 2)
    {
        "streetNumber": (address splitBy(" "))[0],
        "streetName": (address splitBy(" "))[1]
    }
    // 2. Check if address contains "Cnr" / "CNR" / "cnr". No street number will be passed.
    // If there are characters before <cnr>: remove and pass the remaining string starting from <cnr>
    // If the character after <cnr> is not a space, split the word with <cnr>, add space and add the remaining characters.
    else if(lower(address) contains ("cnr"))
    {
        "streetNumber": null,
        "streetName": if (!isWhitespace(substringAfter(lower(address), "cnr")))
                "Cnr " ++ trim(substringAfter(address, address[3]))
            else address
    }
    // 3. Check if address contains "lot / "LOT" / "Lot"
    // Street number should get the word <lot> and lot number.
    // Street name should pass the remaining characters. 
    else if(lower(address) contains("lot"))
    {
        "streetNumber": (address splitBy(" "))[0] ++ " " ++ ((address splitBy(" "))[1] default ""),
        "streetName": trim(substringAfter(address, (address splitBy(" "))[1])) default ""}
    // 4. Check if address contains -
    // Street number will pass the character before and after -
    // Street name will pass the remaining characters. 
    else if (address contains("-"))
    {
        "streetNumber": (
            substringBefore(address, "-") ++ 
            "-" ++ 
            if (substringAfter(address, "-")[0] == " ")
                " " ++ substringBefore(trim(substringAfter(address, "-")), " ")
            else substringBefore(substringAfter(address, "-"), " ")
        ),
        "streetName": if (substringAfter(address, "-")[0] == " ")
                substringAfter(trim(substringAfter(address, "-")), " ")
            else substringAfter(substringAfter(address, "-"), " ")
    }
    //5. Check if address does not contain the strings above and is of more than 2 nodes when split by <space>.
    // Check if the first node is numeric. That would be the street number.
    // The rest would be passed as street name. 
    else if(((address splitBy(" ")) countBy((!isEmpty($)))) > 2)
    {
        "streetNumber": (if(isNumeric((address splitBy(" "))[0])) 
                (address splitBy(" "))[0] 
            else ""),
        "streetName": trim(substringAfter(address, (address splitBy(" "))[0]))
    }
    else {
        "streetNumber": null,
        "streetName": address
    }

// Set address street for streetname and number
// if addressType for manual exists: call splitStreetNameAndNum to split streetNumber and streetName
// else streetNumber will get the default tag for streetNum, and so as streetName
fun getAddressStreet(source, addressType, streetNum, defaultStreetNum, defaultStreetName) = 
    if(!isEmpty(getCustomAttDetail(source, addressType)))
        if(!isEmpty(getCustomAttDetail(source, streetNum)))
            splitStreetNameAndNum(getCustomAttDetail(source, streetNum))
        else 
        {
            streetNumber:  null,
            streetName: null
        }
    else 
        {
            streetNumber:  getCustomAttDetail(source, defaultStreetNum),
            streetName: getCustomAttDetail(source, defaultStreetName) default ""
        }

//Address Manual or QAS
var installationAddressType = 
		if(!isEmpty(getCustomAttDetail(installationAddress."shipping-address", "manualAddressType")))
              "Manual"
        else "QAS"
		
var shippingAddressType = 
		if(!isEmpty(getCustomAttDetail(address."shipping-address", "manualAddressType")))
              "Manual"
        else "QAS"

var previousResidentialAddressType = if(!isEmpty(getCustomAttDetail(rootElement, "previousResidentialGnafPid")))
            "QAS"
        else "Manual"
		
var billingAddressType = if(!isEmpty(getCustomAttDetail(billAddress, "manualAddressType")))
            "Manual"
        else "QAS"
var residentialAddressType = if(!isEmpty(getCustomAttDetail(rootElement, "residentialAddressType")))
            "Manual"
        else "QAS"
        
        
fun getRelocUnitNumber(streetNum) = (
    if (streetNum contains "/") (streetNum splitBy "/")[0]
   else if (streetNum contains "-") (streetNum splitBy "-")[0]
   else ""  
)
fun getRelocStreetNumber(streetNum) = (
    if (streetNum contains "/") (streetNum splitBy "/")[1]
   else if (streetNum contains "-") (streetNum splitBy "-")[1]
   else streetNum  
)
fun getRelocOfflnAddressName(addr) =(
    //if(!isEmpty(getRelocUnitNumber(addr.streetNumber as String))) getRelocUnitNumber(addr.streetNumber as String) ++ "/" ++ getRelocStreetNumber(addr.streetNumber as String) ++ " " ++ addr.streetName as String ++ " " ++ addr.streetType as String ++ ", " ++ addr.subUrb as String ++ ", " ++ addr.state as String
   if(!isEmpty(addr.subAddressNumber)) addr.subAddressNumber as String ++ "/" ++ getRelocStreetNumber(addr.streetNumber as String) ++ " " ++ addr.streetName as String ++ " " ++ addr.streetType as String ++ ", " ++ addr.subUrb as String ++ ", " ++ addr.state as String ++ ", " ++ addr.postcode as String
    
    else getRelocStreetNumber(addr.streetNumber as String) ++ " " ++ addr.streetName as String ++ " " ++ addr.streetType as String ++ ", " ++ addr.subUrb as String ++ ", " ++ addr.state as String ++ ", " ++ addr.postcode as String
) 
var flowTypeChangeReason = getCustomAttDetail(rootElement, "flowTypeChangeReason") default ""     
//Address variables that will hold streetNumber and streetName for each address  
var installationStreetNameNum = getAddressStreet(installationAddress."shipping-address", "manualAddressType", "streetName", shippingAddressStreetNumber, "streetName")      
var shippingStreetNameNum = getAddressStreet(address."shipping-address", "manualAddressType", "streetName", shippingAddressStreetNumber, "streetName")
var prevResidentialStreetNameNum =  getAddressStreet(rootElement, "previousResidentialAddressType", "previousResidentialStreetName", "previousResidentialBuildingNumber", "previousResidentialStreetName")
var billingStreetNameNum = getAddressStreet(billAddress, "manualAddressType", "streetName", billingAddressStreetNumber, "streetName")
var residentialStreetNameNum = getAddressStreet(rootElement, "residentialAddressType", "residentialStreetName", "residentialBuildingNumber", "residentialStreetName")
/////////////////////////////////////////// END OF ADDRESS RELATED VARIABLE AND FUNCTIONS

/////////////////////////////////////////// MEDICARE RELATED      
var cardColor = getCustomAttDetail(rootElement, "cardColour")
var cardColourFlag = getCustomAttDetail(rootElement, "isCardColourFull") default null
var medicareExpiryDate = getCustomAttDetail(rootElement, "cardExpiry") default ""
var dateArr = medicareExpiryDate splitBy (' ') default []
var greenDate = (dateArr[5]++ '-' ++ dateArr[1] ++ '-' ++ dateArr[2]) as Date {format: 'yyyy-MMM-dd'} as String {format: 'MM/yyyy'} default ""
 
var yellowDate = (dateArr[5]++ '-' ++ dateArr[1] ++ '-' ++ dateArr[2]) as Date {format: 'yyyy-MMM-dd'} as String {format: 'dd/MM/yyyy'} default ""

var transformedCardColor = 
if( cardColourFlag == "true" ) "Full"
else
    if ( lower(cardColor) == "g" ) "Green"
    else if ( lower(cardColor) == "b" ) "Blue"
    else if ( lower(cardColor) == "y" ) "Yellow"
    else null
    
var medicareCardNumber = 
if( cardColourFlag == "false" ) (getCustomAttDetail(rootElement, "medicareCardNumber") default "") ++ "-" ++ (getCustomAttDetail(rootElement, "individualReferenceNumber") default "")
else getCustomAttDetail(rootElement, "medicareCardNumber") default ""
/////////////////////////////////////////// END OF MEDICARE RELATED VARIABLE AND FUNCTIONS

/////////////////////////////////////////// Appointment Related      
fun getNbnOptusApptDate(date) = ( ( ( (date as Date)  as String {format: "yyyy-MM-dd'T'00:00:00"} ) as LocalDateTime ++ (getTimeZone(serviceDetails."shipping-address"."state-code")) ) as String {format: "dd/MM/yyyyZZZZ"} ) replace "GMT" with "" default null
fun splitTime(string) = string splitBy("-") as String
fun convertTime(time) = 
    if( isEmpty(time) ) null
    else {
        "fromTime" : ((splitTime(time)[0] scan /[0-9]+[:][0-9]+[A-Z]+/)[0][0] default ((splitTime(time)[0] scan /[0-9]+[A-Z]+/)[0][0] replace ("AM") with (":00AM") replace ("PM") with (":00PM"))) as LocalTime {format: 'h:mma'} as String {format: 'HH:mm'},
        "toTime" : ((splitTime(time)[1] scan /[0-9]+[:][0-9]+[A-Z]+/)[0][0] default ((splitTime(time)[1] scan /[0-9]+[A-Z]+/)[0][0] replace ("AM") with (":00AM") replace ("PM") with (":00PM"))) as LocalTime {format: 'h:mma'} as String {format: 'HH:mm'}
    }
    
var serviceDetails = ({(flatten(shipmentArray) filter (getCustomAttDetail($."shipping-address", "addressType")== "SERVICE"))}) default null

var svcQualificationResponse= if (!isEmpty(serviceQualification)) serviceQualification."$(gnafid)".response else ""
var svcQualificationRes= if (!isEmpty(serviceQualification)) serviceQualification."$(gnafid)".response.checkServiceCoverageResponse.services.service filter ((lower($.family) == "nbn fttp") or (lower($.family) == "nbn cable (hfc)")) else ""
var esqResponse = read((serviceDetails.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='esqResponse')).'__text'[0], "application/json") default null
var nsiResponse =  read((serviceDetails.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='nsiResponse')).'__text'[0], "application/json") default null
var subOrderType = getCustomAttDetail(serviceDetails,'orderType') as String default null
var customerType = (rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "customerType"))[0]."__text"
/////////////////////////////////////////// End of Appointment Related
---

removeEmptyObjects({
    customerAccount: {
    Name: if (customerType ~= "SMB") 
		    	if (customerguestval ~= "true")
		    		((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "businessName"))[0]."__text") 
		    	else if (customerguestval ~= "false")
		    		selectedOrganizationDetails.name
		    	else ((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "businessName"))[0]."__text") 
    	else rootElement.customer.'customer-name',
    Description: rootElement.customer.'customer-name',
    vlocity_cmt__Status__c: 'Active',
    BillingStreet: rootElement.customer.'billing-address'.address1,
    BillingCity: rootElement.customer.'billing-address'.city,
    BillingState: rootElement.customer.'billing-address'.'state-code',
    BillingPostalCode: rootElement.customer.'billing-address'.'postal-code',
    Phone:rootElement.customer.'billing-address'.phone,
    vlocity_cmt__BillingEmailAddress__c:lower(rootElement.customer.'customer-email'),
    "Email_Address__c": lower(rootElement.customer.'customer-email'),
    JARVIS_Customer_ID__c: getCustomAttDetail(rootElement, "selectedCustomerID") default "",
    BAR_ID__c: if(payment."custom-method"."method-name"[0] == "EXISTING_FA") getCustomAttDetail(payment."custom-method"[0], "selectedBillingAccountNumber")
               else getCustomAttDetail(rootElement, "selectedBARId") default "",
    FA_ID__c: if(payment."custom-method"."method-name"[0] == "EXISTING_FA") getCustomAttDetail(payment."custom-method"[0], "selectedBillingAccountFAId")
              else getCustomAttDetail(rootElement, "selectedBillingAccount") default "",
    Jarvis_Account_Status__c: (getCustomAttDetail(rootElement, "accountType") default "" ) replace "Account" with "",
    JARVIS_Customer_Profile_ID__c: getCustomAttDetail(rootElement, "profilePID") default "",
    AccountNumber: readrelocationServiceDataJson.faId default null,
    "Organisation_acn_Id__c": selectedOrganizationDetails.acnId,
    "Organisation_abn_Id__c": selectedOrganizationDetails.abnId,
    "Employee_Count__c": getCustomAttDetail(rootElement, "smbEmployeeCount") as Number default null,
    "Organisation_Type__c": selectedOrganizationDetails."typeRefId",
    "Customer_Type__c": customerType,
    "Billing_Type__c" : if (getCustomAttDetail(rootElement, "customerType") ~= "SMB")"S"
                        else if (getCustomAttDetail(rootElement, "customerType") ~= "CMR")"D"
                        else "",
    "optus_bet_id__c": vars.optus_bet_id
},
customerContact: {
    "Salutation": (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileTitle')).'__text'[0],
    "FirstName": (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileFirstName')).'__text'[0],
    "LastName": (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileLastName')).'__text'[0],
    "Email_Address__c": lower(rootElement.customer.'customer-email'),
    "Preferred_Contact_Method__c": lower((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profilePrefContactMethod')).'__text'[0]),
    "Phone": (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileMobileNumber')).'__text'[0],
    "Email": lower(rootElement.customer.'customer-email'),
   Birthdate:(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileDateOfBirth')).'__text'[0],
    "Personal_ID_Type__c": personalIdTypeCond((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='primaryIDType')).'__text'[0]),
    "Personal_ID_Principle_Identifier__c": 'Principle',
    "Secondary_ID_Type__c": secondaryTypeIdCond((rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='secondaryIDType')).'__text'[0]),

    "Passport_Number__c": getCustomAttDetail(rootElement, whichPassport("passportNumber", "secondaryPassportNumber"
)) default "",
    "Passport_Country__c": countryCodeToText(getCustomAttDetail(rootElement, whichPassport("countryOfIssue", "secondaryPassportCountryOfIssue"
))) default "",
    "Passport_Expiry_Date__c": getCustomAttDetail(rootElement, whichPassport("passportExpiryDate", "secondaryPassportExpiryDate"
)) default "", 
    "Passport_Issue_Date__c": getCustomAttDetail(rootElement, whichPassport("passportIssueDate","secondaryPassportIssueDate")) default "",
    "Passport_First_Name__c": getCustomAttDetail(rootElement, whichPassport("passportFirstName", "secondaryPassportFirstname"
)) default "",
    "Passport_Middle_Name__c": getCustomAttDetail(rootElement, whichPassport("passportAnyName", "secondaryPassportAnyName"
)) default "",
    "Passport_Last_Name__c": getCustomAttDetail(rootElement, whichPassport("passportLastName", "secondaryPassportLastName"
)) default "",
    
    "vlocity_cmt__StateOfIssuance__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='issuingState')).'__text'[0],
    "License_Number__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='licenceNumber')).'__text'[0],
    "License_Expiry_Date__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='licenceExpiryDate')).'__text'[0] default "",
    "MailingStreet":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialAddressLine1')).'__text'[0],
    "MailingCity":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialCity')).'__text'[0],
    "MailingState":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialStateCode')).'__text'[0],
    "MailingPostalCode":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialPostalCode')).'__text'[0],
    "MailingCountry":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialCountry')).'__text'[0],
    "Mailing_Street_Name__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialStreetName')).'__text'[0],
    "Mailing_Building_Number__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialBuildingNumber')).'__text'[0],
    "Mailing_Street_Type__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialStreetType')).'__text'[0],
    "Mailing_GnafPid__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='residentialGnafPid')).'__text'[0],
    "vlocity_cmt__Occupation__c": if (customerType ~= "SMB") ((rootElement."custom-attributes"."custom-attribute" filter ($."@attribute-id" ~= "smbOccupation"))[0]."__text") else (rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='occupationName')).'__text'[0],
    "Employment_Status__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='employmentStatus')).'__text'[0],
    "Employer_Name__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='employersName')).'__text'[0],
    "JARVIS_Contact_ID__c":(rootElement.'custom-attributes'.'custom-attribute' filter ($.'@attribute-id'=='profileContactId')).'__text'[0] default " ",
    "Unit_Number__c": getCustomAttDetail(rootElement, "residentialUnitNumber") default "",
    "Licence_First_Name__c": getCustomAttDetail(rootElement, "licenceFirstName") default "",
    "Licence_Middle_Name__c": getCustomAttDetail(rootElement, "licenceAnyName") default "",
    "Licence_Last_Name__c": getCustomAttDetail(rootElement, "licenceLastName") default "",
    "Medicare_Card_Number__c": medicareCardNumber,
    "Individual_Reference_Number__c": getCustomAttDetail(rootElement, "individualReferenceNumber") default "",
    "Medicare_First_Name__c": getCustomAttDetail(rootElement, "medicareFirstName") default "",
    "Medicare_Middle_Name_Initial__c": getCustomAttDetail(rootElement, "medicareMiddleInitial") default "",
    "Medicare_Last_Name__c": getCustomAttDetail(rootElement, "medicareLastName") default "",
    "Medicare_Card_Colour__c": transformedCardColor,
    "Medicare_Card_Expiry_Date__c": if(cardColor == 'G') greenDate else yellowDate,
    "Residential_Status__c": getCustomAttDetail(rootElement, "residentialStatus") default "",
    "vlocity_cmt__StateOfIssuance__c": getCustomAttDetail(rootElement, "issuingState") default "",
    "Residential_Months_Stay__c": getCustomAttDetail(rootElement, "residentialMonthsStay") default 0,
    "Residential_Years_Stay__c": getCustomAttDetail(rootElement, "residentialYearsStay") default 0,
    "Months_Worked__c": getCustomAttDetail(rootElement, "tenureMonth") default 0,
    "Years_Worked__c": getCustomAttDetail(rootElement, "tenureYear") default 0,
    "Previous_Residential_Months_Stay__c": getCustomAttDetail(rootElement, "previousResidentialMonthsStay") default 0,
    "Previous_Residential_Years_Stay__c": getCustomAttDetail(rootElement, "previousResidentialYearsStay") default 0,
    "Industry_Type__c": getCustomAttDetail(rootElement, "industryType") default "",
    "Medicare_Card_Ind_Ref_Num__c": getCustomAttDetail(rootElement, "individualReferenceNumber") default "",
    "Is_Card_Colour_Full__c": cardColourFlag as Boolean default "",
    "optus_bet_id__c": vars.optus_bet_id,
    "Document_Card_Number__c": if ( (getCustomAttDetail(rootElement, "primaryIDType") == "DRIVER_LICENCE") or (getCustomAttDetail(rootElement, "secondaryIDType") == "DRIVER_LICENCE") ) (getCustomAttDetail(rootElement, "licenceCardNumber")) else ""
    } ++ (if(
        ((getCustomAttDetail(rootElement, "primaryIDType") == "AU_PASSPORT") or
        (getCustomAttDetail(rootElement, "primaryIDType") == "NZ_PASSPORT") or
        (getCustomAttDetail(rootElement, "primaryIDType") == "INTERNATIONAL_PASSPORT"))
            and
        ((getCustomAttDetail(rootElement, "secondaryIDType") == "AU_PASSPORT") or
        (getCustomAttDetail(rootElement, "secondaryIDType") == "NZ_PASSPORT") or
        (getCustomAttDetail(rootElement, "secondaryIDType") == "INTERNATIONAL_PASSPORT"))
    ) 
        {
            "Passport_Country_Additional__c":  countryCodeToText(getCustomAttDetail(rootElement, "secondaryPassportCountryOfIssue"))  default "",
            "Passport_Expiry_Date_Additional__c":  getCustomAttDetail(rootElement, "secondaryPassportExpiryDate")  default "",
            "Passport_First_Name_Additional__c":  getCustomAttDetail(rootElement, "secondaryPassportFirstname")  default "",
            "Passport_Last_Name_Additional__c":  getCustomAttDetail(rootElement, "secondaryPassportLastName")  default "",
            "Passport_Middle_Name_Additional__c":  getCustomAttDetail(rootElement, "secondaryPassportAnyName")  default "",
            "Passport_Number_Additional__c":  getCustomAttDetail(rootElement, "secondaryPassportNumber")  default ""
        }  
    else ({})
    ),
    customerAddress: [
        {
			//Installation Address
            "Name": generateAddressName(
            	        getCustomAttDetail(installationAddress."shipping-address", "buildingName"),
                        installationAddressUnitNumber, 
                        getStreetOrBuildingNumber(getCustomAttDetail(installationAddress."shipping-address", "streetNumber"),getCustomAttDetail(installationAddress."shipping-address", "buildingNumber")), 
                        installationStreetNameNum.streetName default "", 
                        getCustomAttDetail(installationAddress."shipping-address", "streetType") default "",
                        installationAddress."shipping-address".city default "",
                        installationAddress."shipping-address"."state-code" default "",
                        installationAddress."shipping-address"."postal-code" default ""                        
                    ),
            "Street_Type__c": changeSreetTypeToCode(getCustomAttDetail(installationAddress."shipping-address", "streetType")) default "",
            "City__c": installationAddress."shipping-address".city default "",
            "State__c": installationAddress."shipping-address"."state-code" default "",
            "Postcode__c": installationAddress."shipping-address"."postal-code" default "",
            "Country__c": if(!isEmpty(installationAddress."shipping-address"."country-code") and (installationAddress."shipping-address"."country-code" contains ("AU"))) 
            				"AUS" else installationAddress."shipping-address"."country-code" default "",
            "Note__c": getCustomAttDetail(installationAddress, "note") default "",
            "Type__c": "Installation Address",
            "Jarvis_Address_ID__c": "",
            "Street_Name__c": getCustomAttDetail(installationAddress."shipping-address", "streetName") default "",
            "Street_Number__c": getStreetOrBuildingNumber(getCustomAttDetail(installationAddress."shipping-address", "streetNumber"),getCustomAttDetail(installationAddress."shipping-address", "buildingNumber")),
			"Street_Number_Suffix__c": getCustomAttDetail(installationAddress."shipping-address", "streetNumSuffix") default "",
            "Building_Name__c": getCustomAttDetail(installationAddress."shipping-address", "buildingName") default "",
            "Unit_Number__c": installationAddressUnitNumber,
            "Sub_Address_Type__c": changeSubAddressTypeTextToCode(subAddressCond(installationAddress."shipping-address", "manualAddressType", "subAddressType"
)) default "",
            "Address_Entry_Method__c": installationAddressType,
            "optus_bet_id__c": vars.optus_bet_id		
		},
		({
            //Residential Address
            "Name": generateAddressName(
            	getCustomAttDetail(rootElement, "residentialBuildingName"),
                residentialAddressUnitNumber, 
                getStreetOrBuildingNumber(getCustomAttDetail(rootElement, "residentialStreetNumber"),getCustomAttDetail(rootElement, "residentialBuildingNumber")), 
                getCustomAttDetail(rootElement, "residentialStreetName") default "", 
                getCustomAttDetail(rootElement, "residentialStreetType") default "", 
                getCustomAttDetail(rootElement, "residentialCity") default "", 
                getCustomAttDetail(rootElement, "residentialStateCode") default "",
                getCustomAttDetail(rootElement, "residentialPostalCode") default ""
                ),
            "Street_Number__c": getStreetOrBuildingNumber(getCustomAttDetail(rootElement, "residentialStreetNumber"),getCustomAttDetail(rootElement, "residentialBuildingNumber")),
            "Street_Name__c": getCustomAttDetail(rootElement, "residentialStreetName") default "",
			"Street_Number_Suffix__c": getCustomAttDetail(rootElement, "residentialStreetNumSuffix") default "",
            "Building_Name__c": getCustomAttDetail(rootElement, "residentialBuildingName") default "",
            "City__c": getCustomAttDetail(rootElement, "residentialCity") default "",
            "Country__c": getCustomAttDetail(rootElement, "residentialCountry") default "",
            "Postcode__c": getCustomAttDetail(rootElement, "residentialPostalCode") default "",
            "State__c": getCustomAttDetail(rootElement, "residentialStateCode") default "",
            "Street_Type__c": changeSreetTypeToCode(getCustomAttDetail(rootElement, "residentialStreetType")) default "",
            "Unit_Number__c": residentialAddressUnitNumber,
            "Sub_Address_Type__c":changeSubAddressTypeTextToCode(subAddressCond(rootElement, "residentialAddressType", "residentialSubAddressType"
)) default "",
            "Type__c": "Residential Address",
            "Jarvis_Address_ID__c": "",
			"Address_Entry_Method__c": residentialAddressType,
			"optus_bet_id__c": vars.optus_bet_id
        }) if(
                (!isEmpty(getCustomAttDetail(rootElement, "residentialCity")))
                and (
                    (residentialAddressUUID != installationAddressUUID) 
                    or (
                        isEmpty(residentialAddressUUID) and isEmpty(installationAddressUUID)
                    )
                )
            ),

        //Residential Address for Relocation
          ({    
            "Name": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.formattedAddressDisplay default "",
            "Jarvis_Address_ID__c": relocationOfflineResdAddr.selectedAddress.relationInfoList[0].addressId default "",
            "City__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.subUrb default "",
            "Country__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.country.id default "",
            "Postcode__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.postcode default "",
            "State__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.state default "",
            "Street_Name__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.streetName default "",
            "Street_Number__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.streetNumber default "",
            "Street_Type__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.streetType default "",
            "Address_Entry_Method__c": if (!isEmpty (relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.gnafId)) "QAS" else "Manual",
            "Sub_Address_Type__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.subAddressType default "",
            "Unit_Number__c": relocationOfflineResdAddr.selectedAddress.implPhysicalAddress.subAddressNumber default "",  
            "Type__c": "Residential Address",
            "optus_bet_id__c": vars.optus_bet_id       
            }) if (!isEmpty(relocationOfflineResdAddr)),
		
		({
            //Shipping Address (Delivery Address)
            "Name": generateAddressName(
            	        getCustomAttDetail(address."shipping-address", "buildingName"),
                        shippingAddressUnitNumber, 
                        getStreetOrBuildingNumber(getCustomAttDetail(address."shipping-address", "streetNumber"),getCustomAttDetail(address."shipping-address", "buildingNumber")),
                        getCustomAttDetail(address."shipping-address", "streetName") default "",  
                        getCustomAttDetail(address."shipping-address", "streetType") default "",
                        address."shipping-address".city default "",
                        address."shipping-address"."state-code" default "",
                        address."shipping-address"."postal-code" default ""
                    ),
            "Street_Type__c": changeSreetTypeToCode(getCustomAttDetail(address."shipping-address", "streetType")) default "",
            "City__c": address."shipping-address".city default "",
            "State__c": address."shipping-address"."state-code" default "",
            "Postcode__c": address."shipping-address"."postal-code" default "",
            "Country__c": if(!isEmpty(address."shipping-address"."country-code") and (address."shipping-address"."country-code" contains ("AU"))) 
            				"AUS" else address."shipping-address"."country-code" default "",
            "Note__c": getCustomAttDetail(address, "note") default "",
            "Type__c": "Delivery Address",
            "Jarvis_Address_ID__c": getCustomAttDetail(address."shipping-address", "jarvisAddressId") default "",
            "Street_Name__c": getCustomAttDetail(address."shipping-address", "streetName") default "",
            "Street_Number__c": getStreetOrBuildingNumber(getCustomAttDetail(address."shipping-address", "streetNumber"),getCustomAttDetail(address."shipping-address", "buildingNumber")),
			"Street_Number_Suffix__c": getCustomAttDetail(address."shipping-address", "streetNumSuffix") default "",
            "Building_Name__c": getCustomAttDetail(address."shipping-address", "buildingName") default "",
            "Unit_Number__c": shippingAddressUnitNumber,
            "Sub_Address_Type__c": changeSubAddressTypeTextToCode(subAddressCond(address."shipping-address", "manualAddressType", "subAddressType"
)) default "",
            "Address_Entry_Method__c": shippingAddressType,
            "optus_bet_id__c": vars.optus_bet_id
        }) if(
                (
                    (deliveryAddressUUID != installationAddressUUID) 
                    and (deliveryAddressUUID != residentialAddressUUID) 
                    and (relocationFlowType != "RelocationOffline" or relocationFlowType != "RelocationOnline")
                ) 
                or (
                    (deliveryAddressUUID != installationAddressUUID) 
                    and (relocationFlowType == "RelocationOffline" or relocationFlowType == "RelocationOnline") 
                    and (relocationNCDRequired == "true")
                )
            ),
        
        ({
            //Billing Address
            "Name": generateAddressName(
            	getCustomAttDetail(billAddress, "buildingName"),
                billingAddressUnitNumber,
                getStreetOrBuildingNumber(getCustomAttDetail(billAddress, "streetNumber"),getCustomAttDetail(billAddress, "buildingNumber")),
                getCustomAttDetail(billAddress, "streetName") default "",
                getCustomAttDetail(billAddress, "streetType") default "",
                billAddress."city" default "",
                billAddress."state-code" default "",
                billAddress."postal-code" default ""
            ),
            "City__c": billAddress."city" default "",
            "State__c": billAddress."state-code" default "", 
            "Street_Name__c": getCustomAttDetail(billAddress, "streetName") default "",
            "Building_Name__c": getCustomAttDetail(billAddress, "buildingName") default "",
            "Street_Type__c": changeSreetTypeToCode(getCustomAttDetail(billAddress, "streetType")) default "", 
            "Unit_Number__c": billingAddressUnitNumber,
            "Sub_Address_Type__c": changeSubAddressTypeTextToCode(subAddressCond(billAddress,  "manualAddressType", "subAddressType")) default "", 
            "Country__c": "AUS",
            "Postcode__c": billAddress."postal-code" default "", 
            "Type__c": "Billing Address",
            "Street_Number__c": getStreetOrBuildingNumber(getCustomAttDetail(billAddress, "streetNumber"),getCustomAttDetail(billAddress, "buildingNumber")),
			"Street_Number_Suffix__c": getCustomAttDetail(billAddress, "streetNumSuffix") default "",
            "Jarvis_Address_ID__c": getCustomAttDetail(billAddress, "jarvisAddressId") default "",
			"Address_Entry_Method__c": billingAddressType,
			"optus_bet_id__c": vars.optus_bet_id
        }) if(
                (
                    !isEmpty(billAddress."city") 
                    and (installationAddressUUID != billAddressUUID ) 
                    and (residentialAddressUUID != billAddressUUID) 
                    and (deliveryAddressUUID != billAddressUUID)
                ) 
                or (
                    (relocationFlowType == "RelocationOffline" or relocationFlowType == "RelocationOnline") 
                    and (installationAddressUUID != billAddressUUID)
                )
            ),
        //Service Qualification(SQ) Address
        ({
        	 "Name": generateAddressName(
        	 	        svcQualificationAddress.selectedAddress.implPhysicalAddress.buildingName,
                        //svcQualificationAddress.selectedAddress.implPhysicalAddress.unitNumber,
                        svcQualificationAddressUnitNumber,
                        getStreetOrBuildingNumber(svcQualificationAddress.selectedAddress.implPhysicalAddress.streetNumber,svcQualificationAddress.selectedAddress.implPhysicalAddress.blockOrHouseNum), 
                        svcQualificationAddress.selectedAddress.implPhysicalAddress.streetName default "", 
                        svcQualificationAddress.selectedAddress.implPhysicalAddress.streetType default "",
                        svcQualificationAddress.selectedAddress.implPhysicalAddress.subUrb default "",
                        svcQualificationAddress.selectedAddress.implPhysicalAddress.state,
                        svcQualificationAddress.selectedAddress.implPhysicalAddress.postcode default ""
                    ),
        Apartment__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.apartment default "",
        City__c: (if (!isEmpty(svcQualificationAddress.selectedAddress.implPhysicalAddress.subUrb))svcQualificationAddress.selectedAddress.implPhysicalAddress.subUrb 
                 else if (!isEmpty(svcQualificationAddress.selectedAddress.implPhysicalAddress.city)) svcQualificationAddress.selectedAddress.implPhysicalAddress.city 
                 else ""),
        Country__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.country.id default "",
        Floor__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.floor default "",
        Postcode__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.postcode default "",
        Room__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.room default "",
        Unit_Number__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.unitNumber default "",
        State__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.state default "",
        Street_Name__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.streetName default "",
        Block__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.blockOrHouse default "",
        Block_Number__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.blockOrHouseNum default "",
        Building_Name__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.buildingName default "",
        Dev_Name__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.devName default "",
        Address_Entry_Method__c: (if (svcQualificationAddress.selectedAddress.implPhysicalAddress.isUnstructAddressX9 == "1")"Manual" 
        	                     else if(svcQualificationAddress.selectedAddress.implPhysicalAddress.isUnstructAddressX9 == "0") "QAS" 
        	                     else ""),
        Address_Type__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.addressType default "",
        Delivery_Type__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.deliveryType default "",
        Street_Number__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.streetNumber default "",
        Sub_Address_Type__c: changeSubAddressTypeTextToCode(svcQualificationAddress.selectedAddress.implPhysicalAddress.subAddressType) default "",
        Street_Type__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.streetType default "",
        Unit_Number__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.subAddressNumber default "",
        Street_Suffix__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.streetSuffix default "",
        Delivery_Number__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.deliveryNumber default "",
        Build_Classification__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.buildClassification default "",
        City__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.subUrb default "",
        Street_Number_Suffix__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.streetNumberSuffix default "",
        Is_Internatiaonal_Address__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.isInternationalAddressX9 default "",
        Address_Line_1__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.addressLine1 default "",
        Address_Line_2__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.addressLine2 default "",
        GNA_ID__c: svcQualificationAddress.selectedAddress.implPhysicalAddress.gnafId default "",
        Type__c: "SQ Physical Address",
        optus_bet_id__c: vars.optus_bet_id
        }) if (!isEmpty(svcQualificationAddress)),
         
        //Trading Address
        ({
        	"Name": selectedOrganizationDetails.tradingAddress.formattedAddressX9 default "",
        	State__c: selectedOrganizationDetails.tradingAddress.state default "",
            Street_Name__c: selectedOrganizationDetails.tradingAddress.streetName default "",
            Postcode__c: selectedOrganizationDetails.tradingAddress.postcode default "",
            Country__c: selectedOrganizationDetails.tradingAddress.country.name default "",
            City__c: selectedOrganizationDetails.tradingAddress.subUrb default "",
        	Street_Number__c: selectedOrganizationDetails.tradingAddress.streetNumber default "",
            Street_Type__c: selectedOrganizationDetails.tradingAddress.streetType default "",
            Type__c: "Trading Address",
            "optus_bet_id__c": vars.optus_bet_id  
        }) if (!isEmpty(selectedOrganizationDetails.tradingAddress)),
        
        //Previous Address
        ({
		    "Unit_Number__c" : previousAddressUnitNumber,
            
            "City__c": getCustomAttDetail(rootElement, "previousResidentialCity") default"",
            "State__c": getCustomAttDetail(rootElement, "previousResidentialStateCode") default"",
            "Postcode__c": getCustomAttDetail(rootElement, "previousResidentialPostalCode") default"",
            "Country__c": getCustomAttDetail(rootElement, "previousResidentialCountry") default "",
            "Type__c": "Previous Residential Address",
            "Jarvis_Address_ID__c": "",
            "optus_bet_id__c": vars.optus_bet_id,
            "Sub_Address_Type__c": changeSubAddressTypeTextToCode(subAddressCond(rootElement, "previousResidentialAddressType", "previousResidentialSubAddressType"
)) default ""
			} ++ 
            (if(getCustomAttDetail(rootElement, "previousResidentialCountry") != "AUS")
            	{
                    //“Address_Line_1__c” + comma + space + city + comma + space + state.
            		//Previous Residential Address
				    "Name": 
                    (if(!isEmpty(getCustomAttDetail(rootElement, "previousResidentialAddressLine1")))
                        getCustomAttDetail(rootElement, "previousResidentialAddressLine1") ++ ", "
                    else "") ++ getCustomAttDetail(rootElement, "previousResidentialCity") ++ ", " ++ 
                    getCustomAttDetail(rootElement, "previousResidentialStateCode")
                    ,
					"Address_Entry_Method__c": "Manual",
					"Address_Line_1__c" : getCustomAttDetail(rootElement, "previousResidentialAddressLine1") default"",
		            "Address_Line_2__c" : getCustomAttDetail(rootElement, "previousResidentialAddressLine2") default""
            	}
             else
	             {
	             	"Name": generateAddressName(
	             		        getCustomAttDetail(rootElement, "previousResidentialBuildingName"),
		                        previousAddressUnitNumber,
		                        getStreetOrBuildingNumber(getCustomAttDetail(rootElement, "previousResidentialStreetNumber"),getCustomAttDetail(rootElement, "previousResidentialBuildingNumber")),
		                        getCustomAttDetail(rootElement, "previousResidentialStreetName") default "",
		                        getCustomAttDetail(rootElement, "previousResidentialStreetType") default "",
		                        getCustomAttDetail(rootElement, "previousResidentialCity") default "",
		                        getCustomAttDetail(rootElement, "previousResidentialStateCode") default "",
		                        getCustomAttDetail(rootElement, "previousResidentialPostalCode") default ""
		                    ),
	             	"Street_Type__c": changeSreetTypeToCode(getCustomAttDetail(rootElement, "previousResidentialStreetType")) default "",
	             	"Street_Number__c": getStreetOrBuildingNumber(getCustomAttDetail(rootElement, "previousResidentialStreetNumber"),getCustomAttDetail(rootElement, "previousResidentialBuildingNumber")),
            		"Street_Name__c": getCustomAttDetail(rootElement, "previousResidentialStreetName") default "",
					"Street_Number_Suffix__c": getCustomAttDetail(rootElement, "previousResidentialStreetNumSuffix") default "",
                    "Building_Name__c": getCustomAttDetail(rootElement, "previousResidentialBuildingName")  default "",
            		"Address_Entry_Method__c": previousResidentialAddressType,
	             }
            )
		) if(!isEmpty(getCustomAttDetail(rootElement, "previousResidentialCity"))),

        //Previous Address for Relocation
    (removeEmptyObjects({
            "Jarvis_Address_ID__c": relocationOfflinePrevResdAddr.addressId default "",
            "Name": relocationOfflinePrevResdAddr.formattedAddress default "",
            "City__c": relocationOfflinePrevResdAddr.city default"",
            "State__c": relocationOfflinePrevResdAddr.state default"",
            "Postcode__c": relocationOfflinePrevResdAddr.postCode default"",
            "Country__c": relocationOfflinePrevResdAddr.country default"",
            "optus_bet_id__c": vars.optus_bet_id,  
            "Type__c": if (relocationOfflinePrevResdAddr.formattedAddress !=null)"Previous Residential Address" else "",    
           // ("Sub_Address_Type__c": if (sizeOf(relocationOfflinePrevResdAddr.formattedAddress)>80) relocationOfflinePrevResdAddr.formattedAddress[81 to (sizeOf(relocationOfflinePrevResdAddr.formattedAddress)-1)] else "") if (relocationOfflinePrevResdAddr.formattedAddress?)
             ("Sub_Address_Type__c": if (sizeOf(relocationOfflinePrevResdAddr.formattedAddress)>80) relocationOfflinePrevResdAddr.formattedAddress[81 to (sizeOf(relocationOfflinePrevResdAddr.formattedAddress)-1)] else "") if (relocationOfflinePrevResdAddr.formattedAddress != null)
            
    })) if (!isEmpty(relocationOfflinePrevResdAddr)),		    
    ],
    customerAddressUUID:{
            "installationAddressUUID" : installationAddressUUID default "",
            "deliveryAddressUUID" : deliveryAddressUUID default "",
            "residentialAddressUUID" : residentialAddressUUID default "",
            "billingAddressUUID" : billAddressUUID default "",			
        },
        
     customerSQ: {
     	"sqExists": if (!isEmpty(svcQualificationAddress))true else false,
     	("sqData":{
    	"addressMatchID": svcQualificationAddress.matchID default "",
        "marketSgmt": svcQualificationAddress.marketSgmt default "",
        "relationInfoList": svcQualificationAddress.selectedAddress.relationInfoList default "",
        "Order_Feasibility_Status__c": getCustomAttDetail(serviceDetails,'orderFeasibilityStatus') as String default null,
        ("SFCC_eSQResponse__c": read(getCustomAttDetail(serviceDetails,'esqResponse'), "text/plain")) if( !isEmpty(getCustomAttDetail(serviceDetails,'esqResponse')) ),  
        ("Order_Feasibility_Check_Response__c": read(getCustomAttDetail(serviceDetails,'orderFeasibilityCheckResponse'), "text/plain")) if( !isEmpty(getCustomAttDetail(serviceDetails,'orderFeasibilityCheckResponse')) ),
        "NSI_Call_Status__c": getCustomAttDetail(serviceDetails,'nsiCallStatus') as String default null,
        "NSI_Username__c" : nsiResponse.username default null,
        "NSI_Service_Status__c" :  nsiResponse.serviceStatus default null,
        "NSI_GSID__c": nsiResponse.gsId as Number default null,
        "NSI_Market_Segment__c": (if (lower(nsiResponse.marketSegment) == "smb")"CMR" else if (isEmpty(nsiResponse.marketSegment) )"0" else nsiResponse.marketSegment),
        //("NBN_Port_ID__c" : (svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN PORT ID')[0][0]) if( !isEmpty((svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN PORT ID')[0][0]) ),
       // ("NBN_NTD_ID__c" : (svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN NTD ID')[0][0]) if( !isEmpty((svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN NTD ID')[0][0]) ),
        ("NBN_Port_ID__c" : getCustomAttDetail(rootElement, "availablePort")[-1]) if(!isEmpty(getCustomAttDetail(rootElement, "availablePort")) and getCustomAttDetail(rootElement, "orderType") == "ServiceTransfer" ),
        ("NBN_NTD_ID__c" : substringBefore(getCustomAttDetail(rootElement, "availablePort"),"_")) if(!isEmpty(getCustomAttDetail(rootElement, "availablePort")) and getCustomAttDetail(rootElement, "orderType") == "ServiceTransfer" ),
        ("nbnLocationId": ((svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN LOCATION ID')[0][0]) default nbnLocationId) if (!isEmpty(((svcQualificationRes.serviceSpecCharacteristics.serviceSpecCharacteristics.'NBN LOCATION ID')[0][0]) default nbnLocationId)),
        // DSQ mapping
        (NBN_VDSL_MAX_UPSTREAM_SPEED__c: dsqSpeedDetails.NBN_VDSL_MAX_UPSTREAM_SPEED default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //NBN_VDSL_MAX_UPSTREAM_SPEED__c: "Not Available",
        (NBN_VDSL_MAX_UPSTREAM_SPEED_UNIT__c: svcQualificationAddressOrigSq.'NBN VDSL MAX UPSTREAM SPEED UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq)),
        (NBN_VDSL_MIN_UPSTREAM_SPEED__c: dsqSpeedDetails.NBN_VDSL_MIN_UPSTREAM_SPEED default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //NBN_VDSL_MIN_UPSTREAM_SPEED__c: "Not Available",
        (NBN_VDSL_MIN_UPSTREAM_SPEED_UNIT__c: svcQualificationAddressOrigSq.'NBN VDSL MIN UPSTREAM SPEED UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq)),
        (NBN_VDSL_MIN_DOWNSTREAM_SPEED__c: dsqSpeedDetails.NBN_VDSL_MIN_DOWNSTREAM_SPEED default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //NBN_VDSL_MIN_DOWNSTREAM_SPEED__c: "Not Available",
        (NBN_VDSL_MIN_DOWNSTREAM_SPEED_UNIT__c: svcQualificationAddressOrigSq.'NBN VDSL MIN DOWNSTREAM SPEED UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq)),
        (NBN_VDSL_MAX_DOWNSTREAM_SPEED__c: dsqSpeedDetails.NBN_VDSL_MAX_DOWNSTREAM_SPEED default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //NBN_VDSL_MAX_DOWNSTREAM_SPEED__c: "Not Available",
        (NBN_VDSL_MAX_DOWNSTREAM_SPEED_UNIT__c: svcQualificationAddressOrigSq.'NBN VDSL MAX DOWNSTREAM SPEED UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq)),
        (NBN_NHAS_High_Speed_Tier__c: if (dsqSpeedDetails.NBN_NHAS_TC4_HIGH_SPEED_TIERS_1000MBPS ~= "yes") ("1000 Mbps")
        	else if (dsqSpeedDetails.NBN_NHAS_TC4_HIGH_SPEED_TIERS_250MBPS ~= "yes") ("250 Mbps")
        	else if (dsqSpeedDetails.NBN_NHAS_TC4_HIGH_SPEED_TIERS_100MBPS ~= "yes") ("100 Mbps")
        	else ("Not Available")) if (!isEmpty(dsqSpeedDetails)),
        //NBN_NHAS_High_Speed_Tier__c: "Not Available",
        (NBN_NFAS_High_Speed_Tier__c: if (dsqSpeedDetails.NBN_NFAS_TC4_HIGH_SPEED_TIERS_1000MBPS ~= "yes") ("1000 Mbps")
        	else if (dsqSpeedDetails.NBN_NFAS_TC4_HIGH_SPEED_TIERS_250MBPS ~= "yes") ("250 Mbps")
        	else if (dsqSpeedDetails.NBN_NFAS_TC4_HIGH_SPEED_TIERS_100MBPS ~= "yes") ("100 Mbps")
        	else ("Not Available")) if (!isEmpty(dsqSpeedDetails)),
        //NBN_NFAS_High_Speed_Tier__c: "Not Available",
        (TC4_Downstream_Current_Assured_Rate__c: dsqSpeedDetails.NBN_TC4_DOWNSTREAM_CURRENT_ASSURED_RATE default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //TC4_Downstream_Current_Assured_Rate__c: "Not Available",
        (TC4_Upstream_Current_Assured_Rate__c: dsqSpeedDetails.NBN_TC4_UPSTREAM_CURRENT_ASSURED_RATE default "Not Available") if (!isEmpty(dsqSpeedDetails)),
        //TC4_Upstream_Current_Assured_Rate__c: "Not Available",
        (TC4_Downstream_Current_Assured_Rate_Unit__c: svcQualificationAddressOrigSq.'NBN TC4 DOWNSTREAM CURRENT ASSURED RATE UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq)),
        (TC4_Upstream_Current_Assured_Rate_Unit__c: svcQualificationAddressOrigSq.'NBN TC4 UPSTREAM CURRENT ASSURED RATE UNIT OF MEASURE'[0]) if (!isEmpty(svcQualificationAddressOrigSq))        
        }) if (!isEmpty(svcQualificationAddress)) 	
    },              

    customerRelocation:{
        	"RelocationFlowType": relocationFlowType,
        	("RelocationData":{
        		"DisconnectionDate": getCustomAttDetail(rootElement, "disconnectionDate") as Date {format: 'yyyy-MM-dd'} as String {format: 'dd/MM/yyyy'}  default "",
        		"ConnectionDate": getCustomAttDetail(rootElement, "connectionDate") as Date {format: 'yyyy-MM-dd'} as String {format: 'dd/MM/yyyy'}  default "",
				"RelocationDate": getCustomAttDetail(rootElement, "connectionDate") default "",
				"orderCreationDate": rootElement."order-date",
        		"profinstall" : (rootElement."product-lineitems"."product-lineitem") filter($.'product-name'=='Professional Install'),
        		"readrelocationPayload": readrelocationPayload,
        		"readrelocationServiceData": readrelocationServiceData,
        		"relocationNCDRequired": relocationNCDRequired,
        		"reasonText" : prdType.ProductType, // only for Online
        		"OldCharge_Zone" : getCustomAttDetail(rootElement, "relocationOldChargeZone") default "", // only for Online
        		"NewCharge_Zone" : getCustomAttDetail(rootElement, "relocationNewChargeZone") default "", // only for Online
        		"Flow_Type_Change_Reason__c" : getFlowTypeReason(flowTypeChangeReason) default ""

   		
        	})if (relocationFlowType == "RelocationOffline" or relocationFlowType == "RelocationOnline")
        },

    customerOrders: {
        "Payment_Type__c": if(payment."processor-id"[0] == "MANUAL_PAYMENT") "Manual Payment"
            else if(payment."bank-transfer"."routing-number"?) "Direct Debit - Bank Account"
            else if(payment."processor-id"[0] == "BAMBORA_CREDIT")  "Direct Debit - Credit Card"
            else if((payment."custom-method"."method-name"[0] == "PAYMEANS_CREDIT_CARD") or (payment."custom-method"."method-name"[0] == "EXISTING_FA")) "Existing Credit Card"
            else if(payment."processor-id"[0] == "CASH_PAYMENT") "Exception Bambora"
            else null,
        "NBN_Appointment_Date__c": getCustomAttDetail(serviceDetails, "nbnAppointmentDate") default "",
        "NBN_Time_Slot__c": getCustomAttDetail(rootElement, "nbnTimeSlotLabel") default "",
        "NBN_Technician_Instructions__c": getCustomAttDetail(rootElement, "nbnAppointmentInstructions") default "",
        "Optus_Appointment_Date__c": getCustomAttDetail(serviceDetails, "optusAppointmentDate") default "",
        "Optus_Time_Slot__c": getCustomAttDetail(rootElement, "optusTimeSlotLabel") default "",
        "Optus_Technician_Instructions__c": getCustomAttDetail(rootElement, "optusAppointmentInstructions") default "",
        "Current_Home_Phone_Number__c": getCustomAttDetail(rootElement, "phoneLineHomeNumber") default "",
        "Current_Provider__c": getCustomAttDetail(rootElement, "phoneLineProvider") default "",
        "Current_Provider_Account_Number__c": getCustomAttDetail(rootElement, "phoneLineAccountNumber") default "",
        //"Phone_Line_Show_Number__c": getCustomAttDetail(rootElement, "phoneLineShowNumber") default "",
        "Phone_Line_Show_Number__c": getCustomAttDetail(rootElement, "phoneLineShowNumber") as Boolean default null,
        //"Phone_Line_List_Number__c": getCustomAttDetail(rootElement, "phoneLineListNumber") default "",
        "Phone_Line_List_Number__c": getCustomAttDetail(rootElement, "phoneLineListNumber") as Boolean default null,
        //"Card_Token__c": getCustomAttDetail(payment."credit-card", "secureTransactionToken") default "",
        "Account_Holder__c": payment."bank-transfer"."account-holder"[0] default "",
        "BSB_Number__c": payment."bank-transfer"."routing-number"[0] default "",
        "Account_Number__c": getCustomAttDetail(payment."bank-transfer"[0], "bankAccountNumber") default "",
        "Bank_Branch__c": getCustomAttDetail(payment."bank-transfer"[0], "bankBranch") default "",
        "Bank_Code__c": getCustomAttDetail(payment."bank-transfer"[0], "bankCode") default "",
        "Bank_Name__c": getCustomAttDetail(payment."bank-transfer"[0], "bankName") default "",   
        "BillingCity": billAddress.city default "",
        "BillingCountry": "AUS" default "",
        "BillingPostalCode": billAddress."postal-code" default "",
        "BillingState": billAddress."state-code" default "",
        "BillingStreet": billAddress."address1" default "",
        "ShippingAddress" : address."shipping-address"."address1" default "",
        "ShippingCity": address."shipping-address"."city" default "",
        "ShippingPostalCode": address."shipping-address"."postal-code" default "",
        "ShippingState": address."shipping-address"."state-code" default "",
        "ShippingStreet": address."shipping-address"."address1" default "",
        "ShippingCountry": if(address."shipping-address"."country-code" == "AU") "AUS" else (address."shipping-address"."country-code" default ""), 
        "Total_Monthly_in_SFCC__c": getCustomAttDetail(rootElement, "totalAdjustedMonthlyCostValue") default "",
        "Total_One_Off_in_SFCC__c": getCustomAttDetail(rootElement, "totalUpfrontCostValue") default "",
        "Minimum_Total_Cost_in_SFCC__c": getCustomAttDetail(rootElement, "minimumTotalCostValue") default "",
        "Price_Check_Required__c": true,
        "SessionID__c": getCustomAttDetail(rootElement, "sessionId") default "",
        "ID_Check_Status_Secondary_ID__c":  getCustomAttDetail(rootElement, "secondaryIdCheckStatus")  default "",
        
        "Optus_Appointment_fromTime__c": (convertTime(getCustomAttDetail(serviceDetails,'optusTimeSlotLabel')).fromTime as Time) as String {format : "HH:mm:ss.000'Z'"} default null,
		"Optus_Appointment_toTime__c": (convertTime(getCustomAttDetail(serviceDetails,'optusTimeSlotLabel')).toTime as Time) as String {format : "HH:mm:ss.000'Z'"} default null,
		("Optus_Appointment_Ref__c": read(getCustomAttDetail(serviceDetails,'optusAppointmentResponse'), "text/plain")) if( !isEmpty(getCustomAttDetail(serviceDetails,'optusAppointmentResponse')) ),
		"Optus_Appointment_ID__c": getCustomAttDetail(serviceDetails,'optusAppointmentId') as String default null,
		"Optus_Appointment_Response_Date__c": getNbnOptusApptDate(getCustomAttDetail(serviceDetails,'optusAppointmentDate')) default null,
		
		"NBN_Appointment_fromTime__c" : (convertTime(getCustomAttDetail(serviceDetails,'nbnTimeSlotLabel')).fromTime as Time) as String {format : "HH:mm:ss.000'Z'"} default null,
		"NBN_Appointment_toTime__c" : (convertTime(getCustomAttDetail(serviceDetails,'nbnTimeSlotLabel')).toTime as Time) as String {format : "HH:mm:ss.000'Z'"} default null,
		("NBN_Appointment_Ref__c" : read(getCustomAttDetail(serviceDetails,'NBNAppointmentResponse'), "text/plain")) if( !isEmpty(getCustomAttDetail(serviceDetails,'NBNAppointmentResponse')) ),
		"NBN_Appointment_ID__c" : getCustomAttDetail(serviceDetails,'nbnAppointmentId') as String default null,
		"NBN_Appointment_Response_Date__c" : getNbnOptusApptDate(getCustomAttDetail(serviceDetails,'nbnAppointmentDate')) default null,
		"NBN_Service_Transfer_Flag__c": if ((lower(subOrderType)) == 'servicetransfer') "Y" else "N",
		"NBN_Connect_Outstanding_Flag__c": if (((lower(subOrderType))) == 'connectoutstanding') "Y" else "N",
		"New_Dev_Consent_Flag__c": if((svcQualificationResponse.'nbnDevChargeFlag') == "Y")"Yes" else "No",
		"NBN_Installation_Charge_Flag__c": if((getCustomAttDetail(serviceDetails,'nbnInstallationCharge') == "true" ))"Yes" else "No",
		"Service_Class__c": getCustomAttDetail(serviceDetails,'serviceClass') as Number default null,
		"Service_Provider_ID__c": (esqResponse.siteRestriction.supportingProduct.serviceProviderId)[0] as Number default null,
		"Demand_Type__c": getCustomAttDetail(serviceDetails,'demandType') as String default null,
		"Sub_Order_Type__c": subOrderType,
		"Service_Provider_Name__c": getCustomAttDetail(serviceDetails,'epidName') as String default null,
		"Installation_Workforce__c": getCustomAttDetail(serviceDetails,'installationWorkforce') as String default null,
		"Site_Contact_Details__c": getCustomAttDetail(serviceDetails,'nbnAppointmentContactType') as String default null
      }
})