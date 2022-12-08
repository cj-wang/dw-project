%dw 2.0
output application/json

var productOffering = payload.ProductOffering[0]
var productSpecCharArr = productOffering.ProductSpecificationCharacteristicValueUse
var allBOsArr= flatten(productOffering.ProductOfferingPriceRef..BillingOffers)

fun mapAllBillingOffers() = do {
    var allMappedBOs = productSpecCharArr map (prodSpecChar) -> {
        mappedBOs: allBOsArr map (billingOffer) -> {
            Product_Offer_ID__c: productOffering.ID,
            Product_Spec_RelationID__c: prodSpecChar.RelationID,
            Product_Spec_ID__c: prodSpecChar.ProductSpecRef.ID[0],
            Product_Spec_Name__c: prodSpecChar.ProductSpecRef.Name,
            Billing_Offer_PO_ID__c: billingOffer.ID,
            Billing_Offer_RelationID__c: billingOffer.RelationID,
            Billing_Offer_ParentRelationID__c: billingOffer.ParentRelationID,
            Billing_Offer_Inclusion__c: billingOffer.Inclusion,
            Billing_Offer_ID__c: billingOffer.Offer[0].ID[0],
            Billing_Offer_Name__c: billingOffer.Offer[0].Name,
            External_ID__c: productOffering.ID ++ prodSpecChar.RelationID ++ billingOffer.Offer[0].ID[0]
        }
    }
    ---
    flatten(allMappedBOs.*mappedBOs)

}
---
mecRelArr: mapAllBillingOffers()