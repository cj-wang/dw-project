%dw 2.0
output application/json skipNullOn = "everywhere"

fun changedCharacteristics (node) = if(!isEmpty(node)) node map (characteristicValue) -> {
    characteristicID: characteristicValue.characteristicID,
    value: characteristicValue.value
} else null

fun getProduct(node, isParentCharacteristicValue) =
if(!isEmpty(node))
{
            (changedCharacteristics: if(!isEmpty(changedCharacteristics(node.characteristicValueUpdate))) changedCharacteristics(node.characteristicValueUpdate) else null) if(isParentCharacteristicValue),
            (changedCharacteristics: if(!isEmpty(changedCharacteristics(node.productSpecificationCatalogIDRef.characteristicValueUpdate))) changedCharacteristics(node.productSpecificationCatalogIDRef.characteristicValueUpdate) else null) if(!isParentCharacteristicValue),
            billingOfferID: node.productSpecificationCatalogIDRef.billingOfferID,
            businessType: node.productSpecificationCatalogIDRef.businessType,
            parentProductID: node.productSpecificationCatalogIDRef.parentProductID,
            parentProductSpecContainmentID: node.productSpecificationCatalogIDRef.parentProductSpecContainmentID,
            parentTemporaryID: node.productSpecificationCatalogIDRef.parentTemporaryID,
            productID: node.productSpecificationCatalogIDRef.productID,
            productSpecContainmentID: node.productSpecificationCatalogIDRef.productSpecContainmentID,
            productSpecPricingID: node.productSpecificationCatalogIDRef.productSpecPricingID,
            productSpecID: node.productSpecificationCatalogIDRef.productSpecID,
            simpleProductSpecID: node.productSpecificationCatalogIDRef.simpleProductSpecID,
            temporaryID:node.productSpecificationCatalogIDRef.temporaryID,
            oneTimeChargesOverrideInformation: if (!isEmpty(node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation)) {
            	overrideAmount: node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation.overrideAmount,
            	allowedOverrideType: node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation.allowedOverrideType,
            	overrideAmountType: node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation.overrideAmountType,
            	overrideReason: node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation.overrideReason,
            	overrideReasonFreeText: node.productSpecificationCatalogIDRef.oneTimeChargesOverrideInformation.overrideReasonFreeText
            }else null,
            recurringChargesOverrideInformation: if (!isEmpty(node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation)) {
            	overrideAmount: node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation.overrideAmount,
            	allowedOverrideType: node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation.allowedOverrideType,
            	overrideAmountType: node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation.overrideAmountType,
            	overrideReason: node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation.overrideReason,
            	overrideReasonFreeText: node.productSpecificationCatalogIDRef.recurringChargesOverrideInformation.overrideReasonFreeText
            }else null,
            replaceDefault: node.productSpecificationCatalogIDRef.replaceDefault
    }
else null

fun getProductChanges(product) =
	if(!isEmpty(product))
		{
	        newSimpleProducts: (product map (node) -> if((node.actionType == "add") and node.productType=="atomic") getProduct(node,false) else null) - null,
	
	        newContainedProducts: (product map (node) -> if((node.actionType == "add") and node.productType=="composite") getProduct(node,true) else null) - null,
	
	        newAssignedBillingOffers: (product map (node) -> if((node.actionType == "add") and node.productType=="offer") getProduct(node,true) else null) - null,
	
	        removedSimpleProducts: (product map (node) -> if((node.actionType == "remove") and node.productType=="atomic") getProduct(node,true) else null) - null,
	
	        removedAssignedBillingOffers: (product map (node) -> if((node.actionType == "remove") and node.productType=="offer") getProduct(node,true) else null) - null,
	
	        removedContainedProducts: (product map (node) -> if((node.actionType == "remove") and node.productType=="composite") getProduct(node,true) else null) - null,
	
	        changedSimpleProducts: (product map (node) -> if((node.actionType == "change") and node.productType=="atomic") getProduct(node,true) else null) - null,
	        
	        changedContainedProducts: (product map (node) -> if((node.actionType == "change") and node.productType=="composite") getProduct(node,true) else null) - null,
	        
	        changedAssignedBillingOffers: (product map (node) -> if((node.actionType == "change") and node.productType=="offer") getProduct(node,true) else null) - null,
	        
	        resumedContainedProducts: (product map (node) -> if((node.actionType == "resume") and node.productType=="composite") getProduct(node,true) else null) - null,
	        
	        suspendedContainedProducts: (product map (node) -> if((node.actionType == "suspend") and node.productType=="composite") getProduct(node,true) else null) - null 
		}
	else null
	


fun getItems(node) =
if(!isEmpty(node))
			node map (productOrderItem) -> {
				basicPriceSchemaID: productOrderItem.basicPriceSchemaID,
				contractLengthX8: productOrderItem.contractLength,
				dealerIDX8: productOrderItem.dealerID,
				npcFirstLoad: productOrderItem.npcFirstLoad,
                npcFirstLoadfromNPD: productOrderItem.npcFirstLoadfromNPD,
				productOrderItemID: productOrderItem.productOrderItemID,
				productOrderItemReferenceNumber: productOrderItem.productOrderItemReferenceNumber,
                productOfferingIdX8: productOrderItem.productOfferingID,
                productOfferingProductSpecID: productOrderItem.productOfferingProductSpecID,
                productOfferingInstanceID: productOrderItem.productOfferingInstanceID,
                newProductOfferingID: productOrderItem.newProductOfferingID,
                existingProductOfferingID: productOrderItem.existingProductOfferingID,
                temporaryID: productOrderItem.temporaryID,
				vendorIDX8: productOrderItem.vendorID,
				productID: productOrderItem.productID,
				connectionDate: productOrderItem.connectionDate,
				disconnectionDate: productOrderItem.disconnectionDate,
				dynamicAttributeAtOALevel:  if (!isEmpty(productOrderItem.characteristicValues)) productOrderItem.characteristicValues map(characteristicValue) ->
				{
					name: characteristicValue.name,
					value: characteristicValue.value
				} else null,
				implNewProductsData: if (!isEmpty(productOrderItem.newProducts)) productOrderItem.newProducts map (product) -> 
			    {
			    	npcFirstLoad: product.npcFirstLoadfromNPD,
			        newProduct: {
			        	temporaryID: product.temporaryID,
			            basicPriceSchemaID: product.basicPriceSchemaID,
			            productChanges: if (!isEmpty(product.productRefOrValue))
			            					filteredProductChanges(getProductChanges(product.productRefOrValue))
			            				 else null ,
			            vendorIDX8: product.vendorID,
			            dealerIDX8: product.dealerID,
			            contractLengthX8: product.contractLength,
			            productOfferingProductSpecID: product.productOfferingProductSpecID            
			        }
			    }else null,
			    productForReplacement: if (!isEmpty(productOrderItem.newProducts)) productOrderItem.newProducts map (product) -> 
			    	{
			    		productOrderItemReferenceNumber: product.productOrderItemReferenceNumber,
                		newBasicPriceSchemaID: product.basicPriceSchemaID,
			            newProductOfferingProductSpecID: product.newProductOfferingProductSpecID,
			            orderActionTypeX8: product.orderActionType,
			            vendorIDX8: product.vendorID,
			            dealerIDX8: product.dealerID,
			            contractLengthX8: product.contractLength,
			            productOrderItemID: product.productOrderItemID,
			            productID: product.productID,
			            orderActionReasonX8: product.orderActionReason,
			            productChanges: if (!isEmpty(product.productRefOrValue))
			            					filteredProductChanges(getProductChanges(product.productRefOrValue))
			            				 else null ,
						
			    	}else null,
			    productOrderItemDetails: {
			    	reasonText: productOrderItem.reasonText,
			    	externalID: productOrderItem.externalID,
			    	"type": productOrderItem."type",
			    	reason: productOrderItem.reason
			    },
				productChanges: if(!isEmpty(productOrderItem.productRefOrValue)) 
									filteredProductChanges(getProductChanges(productOrderItem.productRefOrValue))
								else null
			}
else null


fun getInstallationAddressFromSQ(node) =
if(!isEmpty(node))
{
	county: node.county.name,
	formattedAddress1: node.formattedAddress1,
	formattedAddress2: node.formattedAddress2,
	formattedAddress3: node.formattedAddress3,
	formattedAddress4: node.formattedAddress4,
	postalCode: node.postcode,
	town: node.town,
	apartment: node.apartment,
	city: node.city,
    country: node.country.name,
	floor: node.floor,
	room: node.room,
	buildingName: node.buildingName,
	streetNumber: node.streetNumber,
	street: node.streetName,
	xsubAddressTypeX9: node.subAddressType,
	xinvalidAddressX9: node.invalidAddress,
	xsubAddressNumberX9: node.subAddressNumber,
	xstreetTypeX9: node.streetType,
	xaddressTypeX9: node.addressType,
	xadditionalInfoX9: node.additionalInfo,
	xdeliveryTypeX9: node.deliveryType,
	xaddressMatchTypeX9: node.addressMatchType,
	latitude: node.latitude,
	longitude: node.longitude,
	id: node.addressId,
	state: node.state
}
else null

fun getReturnConfigurationData(node) =
if(!isEmpty(node))
{
	summaryInd: node.summaryInd,
	topLevelProductData: node.topLevelProductData,
	catalogDataInd: node.catalogDataInd,
	crossProductsDiscountsDataInd: node.crossProductsDiscountsDataInd,
	productConfigurationInd: node.productConfigurationInd,
	quotedPricesInd: node.quotedPricesInd,
	quotedTaxInd: node.quotedTaxInd,
	previousQuotedRecurringPricesInd: node.previousQuotedRecurringPricesInd,
	quotedProrationInd: node.quotedProrationInd
}
else null

fun getImplCheckServiceCoverageData(node) =
if(!isEmpty(node))
{
	sqResponsePayload: node.sqResponsePayload,
	sqTransactionIDX9: node.sqTransactionID,
	technologicalAddressID: node.technologicalAddressID,
	installationAddressID: node.installationAddressID,
	technology: node.technology,
	gnafID: node.gnafID,
	
	installationAddressFromSQ: if (!isEmpty(node.installationAddress)) getInstallationAddressFromSQ(node.installationAddress) else null
}
else null

fun filteredProductChanges(node) =
	if(!isEmpty(node))
		{
			newSimpleProducts: if(sizeOf(node.newSimpleProducts) != 0) node.newSimpleProducts else null,
	
	        newContainedProducts: if(sizeOf(node.newContainedProducts) != 0) node.newContainedProducts else null,
	
	        newAssignedBillingOffers: if(sizeOf(node.newAssignedBillingOffers) != 0) node.newAssignedBillingOffers else null,
	
	        removedSimpleProducts: if(sizeOf(node.removedSimpleProducts) != 0) node.removedSimpleProducts else null,
	
	        removedAssignedBillingOffers: if(sizeOf(node.removedAssignedBillingOffers) != 0) node.removedAssignedBillingOffers else null,
	
	        removedContainedProducts: if(sizeOf(node.removedContainedProducts) != 0) node.removedContainedProducts else null,
	
	        changedSimpleProducts: if(sizeOf(node.changedSimpleProducts) != 0) node.changedSimpleProducts else null,
	        
	        changedContainedProducts: if(sizeOf(node.changedContainedProducts) != 0) node.changedContainedProducts else null,
	        
	        changedAssignedBillingOffers: if(sizeOf(node.changedAssignedBillingOffers) != 0) node.changedAssignedBillingOffers else null,
	        
	        resumedContainedProducts: if(sizeOf(node.resumedContainedProducts) != 0) node.resumedContainedProducts else null,
	        
	        suspendedContainedProducts: if(sizeOf(node.suspendedContainedProducts) != 0) node.suspendedContainedProducts else null
	        
		}
	else null 

fun getImplProductInOrderConfiguration(node) =
if(!isEmpty(node) and !isEmpty(node.productOrderItemID))
{
  npcFirstLoad: node.npcFirstLoad,
  productOrderItemReferenceNumber: node.productOrderItemReferenceNumber,
  productOrderItemID: node.productOrderItemID,
  basicPriceSchemaID: node.basicPriceSchemaID,
  dynamicAttributeAtOALevel: node.dynamicAttributeAtOALevel,
  vendorIDX8: node.vendorIDX8,
  dealerIDX8: node.dealerIDX8,
  contractLengthX8: node.contractLengthX8,
  productChanges: node.productChanges
}
else null

fun getImplNewOfferingConfiguration(node) =
if(!isEmpty(node) and !isEmpty(node.productOfferingIdX8))
{
	npcFirstLoad: node.npcFirstLoad,
	productOfferingIdX8: node.productOfferingIdX8,
    implNewProductsData: if (!isEmpty(node.implNewProductsData)) node.implNewProductsData map (product) -> 
    {
    	npcFirstLoad: product.npcFirstLoad,
        newProduct: if (!isEmpty(product.newProduct)) {
        	temporaryID: product.newProduct.temporaryID,
            basicPriceSchemaID: product.newProduct.basicPriceSchemaID,
            productChanges: product.newProduct.productChanges,
            vendorIDX8: product.newProduct.vendorIDX8,
            dealerIDX8: product.newProduct.dealerIDX8,
            contractLengthX8: product.newProduct.contractLengthX8,
            productOfferingProductSpecID: product.newProduct.productOfferingProductSpecID            
        } else null
    }else null   
}
else null

fun getImplNewProductInOfferingInstanceConfiguration(node) =
	if(!isEmpty(node) and !isEmpty(node.productOfferingInstanceID))
		{
			productOfferingInstanceID: node.productOfferingInstanceID,
			implNewProductsData: if (!isEmpty(node.implNewProductsData)) node.implNewProductsData map (product) -> 
		    {
		    	npcFirstLoad: product.npcFirstLoad,
		        newProduct: {
		        	temporaryID: product.newProduct.temporaryID,
		            basicPriceSchemaID: product.newProduct.basicPriceSchemaID,
		            productChanges: product.newProduct.productChanges,
		            vendorIDX8: product.newProduct.vendorIDX8,
		            dealerIDX8: product.newProduct.dealerIDX8,
		            contractLengthX8: product.newProduct.contractLengthX8,
		            productOfferingProductSpecID: product.newProduct.productOfferingProductSpecID            
		        }
		    }else null   
		}
	else null
	
fun getReplaceProductOfferingConfiguration(node) = 
	if(!isEmpty(node) and !isEmpty(node.newProductOfferingID))
		{
			newProductOfferingID: node.newProductOfferingID,
			existingProductOfferingID: node.existingProductOfferingID,
			productForReplacement: node.productForReplacement map (product) -> 
			    	{
			    		productOrderItemReferenceNumber: product.productOrderItemReferenceNumber,
                		newBasicPriceSchemaID: product.basicPriceSchemaID,
			            newProductOfferingProductSpecID: product.newProductOfferingProductSpecID,
			            orderActionTypeX8: product.orderActionTypeX8,
			            vendorIDX8: product.vendorIDX8,
			            dealerIDX8: product.dealerIDX8,
			            contractLengthX8: product.contractLengthX8,
			            productOrderItemID: product.productOrderItemID,
			            productID: product.productID,
			            orderActionReasonX8: product.orderActionReasonX8,
			            productChanges: product.productChanges
			    	}
		}
	else null

fun getImplConfigureMoveProduct(node) = 
	if(!isEmpty(node.productID))
	{
		productID: node.productID,
		connectionDate: node.connectionDate,
		disconnectionDate: node.disconnectionDate,
		productOrderItemDetails: {
			reasonText: node.productOrderItemDetails.reasonText,
			externalID: node.productOrderItemDetails.externalID,
			"type": node.productOrderItemDetails."type",
			reason: node.productOrderItemDetails.reason
		}
	}
	else null
	
fun ImplNewOfferingConfiguration(node, filterValue) =
                
                	((getItems(node filter $.context == filterValue map $)) map ((value) -> getImplNewOfferingConfiguration(value))) - null
               
                
               
---
{
	ImplCreateUpdateAddProductOfferConfigurationRequest: {
		runCompatibilityRules: payload.productOrder.productOrderRequestSpecification.runCompatibilityRules,
		activityForConfiguration: payload.productOrder.productOrderRequestSpecification.activityForConfiguration,
		returnConfigurationData: getReturnConfigurationData(payload.productOrder.productOrderRequestSpecification),
		skipMandatoryChecksX8: payload.productOrder.productOrderRequestSpecification.skipMandatoryChecks,
		generateEquipmentOA: payload.productOrder.productOrderRequestSpecification.generateEquipmentOA,
		customerIDX8: payload.productOrder.party.customerId,
		addDefaultChildItemsImplicitly: payload.productOrder.productOrderRequestSpecification.addDefaultChildItemsImplicitly,
		returnRemovedItems: payload.productOrder.productOrderRequestSpecification.returnRemovedItems,
		saveIfCompatibilityRulesFailed: payload.productOrder.productOrderRequestSpecification.saveIfCompatibilityRulesFailed,
		callQuoteForOtherProducts: payload.productOrder.productOrderRequestSpecification.callQuoteForOtherProducts,
		calculateMTC: payload.productOrder.productOrderRequestSpecification.calculateMTC,
		settingsView: payload.productOrder.productOrderRequestSpecification.settingsView,
		returnConfiguration: payload.productOrder.productOrderRequestSpecification.returnConfiguration,
		offerAddOnsX8: payload.offerAddOns,
		productOrderID: payload.productOrder.productOrderId,
		orderReferenceNumber: payload.productOrder.orderReferenceNumber,
		implCheckServiceCoverageData: getImplCheckServiceCoverageData(payload.productOrder.relatedPlace),
		configurationLevel: payload.productOrder.productOrderRequestSpecification.configurationLevel,
		confirmationMessagesApproved: payload.productOrder.productOrderRequestSpecification.confirmationMessagesApproved,
		esqResponsePayload: payload.productOrder.productOrderRequestSpecification.esqResponsePayload,
		nbnFeasibilityResponsePayload: payload.productOrder.productOrderRequestSpecification.nbnFeasibilityResponsePayload,
		returnRemovedByReplaceItems: payload.productOrder.productOrderRequestSpecification.returnRemovedByReplaceItems,
		upfrontTaxRequiredX8: payload.productOrder.productOrderRequestSpecification.upfrontTaxRequired,
		
		implCreateProductOrderRequest: if(!isEmpty(payload.productOrder.productOrderItem.context))(if(payload.productOrder.productOrderItem.context map $ contains "new") {
			implNewOfferingConfiguration:
            if(!isEmpty(payload.productOrder.productOrderItem.productOfferingID))
		(if(sizeOf(ImplNewOfferingConfiguration(payload.productOrder.productOrderItem, "new")) != 0 ) ImplNewOfferingConfiguration(payload.productOrder.productOrderItem, "new") else null) else null,

		dynamicAttributeAtOrderLevel: flatten((payload.productOrder.contextCharacteristicValue filter $.context == "new").characteristicValues) map (characteristicValues) -> {
			    name: characteristicValues.name,
				value: characteristicValues.value 
			}
		}else null )else null,

		implUpdateProductOrderRequest: if(!isEmpty(payload.productOrder.productOrderItem.context))(if(payload.productOrder.productOrderItem.context map $ contains "update") {
			implProductInOrderConfiguration: 
                if(!isEmpty(payload.productOrder.productOrderItem.productOrderItemID)) 
                	(getItems(payload.productOrder.productOrderItem)) map ((value) -> getImplProductInOrderConfiguration(value))
                else null,

            implNewOfferingConfiguration:
            if(!isEmpty(payload.productOrder.productOrderItem.productOfferingID)) (
                if(sizeOf(ImplNewOfferingConfiguration(payload.productOrder.productOrderItem, "update")) != 0 ) ImplNewOfferingConfiguration(payload.productOrder.productOrderItem, "update") else null) else null,
                
            implNewProductInOfferingInstanceConfiguration:
            	if(!isEmpty(payload.productOrder.productOrderItem.productOfferingInstanceID))
            		(getItems(payload.productOrder.productOrderItem)) map ((value) -> getImplNewProductInOfferingInstanceConfiguration(value))
           		else null,

			dynamicAttributeAtOrderLevel: flatten((payload.productOrder.contextCharacteristicValue filter $.context == "update").characteristicValues) map (characteristicValues) -> {
			    name: characteristicValues.name,
				value: characteristicValues.value 
			}
		}else null )else null,
		
		implReplaceProductOrderRequest: if(!isEmpty(payload.productOrder.productOrderItem.context))(if(payload.productOrder.productOrderItem.context map $ contains "replace") {
			replaceProductOfferingConfiguration:
				if((!isEmpty(payload.productOrder.productOrderItem.newProductOfferingID)) or (!isEmpty(payload.productOrder.productOrderItem.existingProductOfferingID))) 
                	(getItems(payload.productOrder.productOrderItem)) map ((value) -> getReplaceProductOfferingConfiguration(value))
                else null,
                
            dynamicAttributeAtOrderLevel: flatten((payload.productOrder.contextCharacteristicValue filter $.context == "replace").characteristicValues) map (characteristicValues) -> {
			    name: characteristicValues.name,
				value: characteristicValues.value 
			}
		}else null )else null,
		
		assignedProductConfiguration:  if(!isEmpty(payload.productOrder.productOrderItem.context))(if(payload.productOrder.productOrderItem.context map $ contains "assign") 
				(getItems(payload.productOrder.productOrderItem filter $.context == "assign") )
            else null )else null,
            
        implMoveProductConfiguration:
        	if(!isEmpty(payload.productOrder.productOrderItem.context))(if(payload.productOrder.productOrderItem.context map $ contains "move") {
        		implConfigureMoveProduct: 
        			if(!isEmpty(payload.productOrder.productOrderItem.productID))
        				(getItems(payload.productOrder.productOrderItem)) map ((value) -> getImplConfigureMoveProduct(value))
        			else null
        		
        }else null )else null
		
	}
}