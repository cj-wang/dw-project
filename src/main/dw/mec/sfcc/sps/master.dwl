%dw 2.0
import * from dw::core::Strings
// import getArrayValue from customFunctionModule::customFunctions
output application/xml

fun attRefValue(loc, strArg: String) = (loc filter $.Item[0] == strArg)[0].Default
fun getAllowedVarAttributes(model: String, attrList: Object) = attrList[model] default attrList["default"]
fun getMasterAttributes(loc, strArg: String) = (((flatten(loc..AttributesRef) filter $.Item[0] == strArg).Default default []) distinctBy (attr) -> attr) orderBy $
/**
* Describes the `specialCharMapping` function purpose.
*
* === Parameters
*
* [%header, cols="1,1,3"]
* |===
* | Name | Type | Description
* | `strToUpdate` | Any | 
* |===
*
* === Example
*
* This example shows how the `specialCharMapping` function behaves under different inputs.
*
* ==== Source
*
* [source,DataWeave,linenums]
* ----
* %dw 2.0
* output application/json
* ---
*
*
* ----
*
* ==== Output
*
* [source,Json,linenums]
* ----
*
* ----
*
*/
fun specialCharMapping(strToUpdate) =  if(strToUpdate contains "\"") strToUpdate replace  ("\"") with "-inch"
                             else if (strToUpdate contains "'") strToUpdate replace  ("'") with "-"
                             else if (strToUpdate contains "\\") strToUpdate replace ("\\") with "-"
                             else if (strToUpdate contains "+") strToUpdate replace ("+") with "-plus"
                             else if (strToUpdate contains "<") strToUpdate replace ("<") with "-less"
                             else if (strToUpdate contains ">") strToUpdate replace (">") with "-greater"
                             else if (strToUpdate contains "&") strToUpdate replace ("&") with "-"
                             else strToUpdate

fun isSalesChannelValid(salesChannelSpec) = isEmpty(salesChannelSpec) or (!isEmpty(flatten(salesChannelSpec) filter ((sc) -> sc.Code[0] == "SS")))
fun isSPSNotExpired(saleExpirationDate) = isEmpty(saleExpirationDate) or (saleExpirationDate > now())

var modelGroup = payload[0]
var modelName = trim((payload pluck $$ as String)[0])
var variantAtomSpec = payload[0][0].AtomicProductSpecification[0]

// var variationAttributesList = getAllowedVarAttributes(modelName,vars.variationAttributes) 
var variationAttributesList = ["Color_BCC", "Internal_Memory_BCC", "Screen_Size_BCC", "Band_Type_BCC", "Band_Size_BCC", "Band_Colour_BCC"]

var allowedAttributes = ["Brand_BCC","Device_Type_BCC","Equipment_Type_BCC","Model_BCC"]
//C2BS-20503 Exclude variants that are expired and not mapped to SS channel
var specIds = (modelGroup.AtomicProductSpecification map ((item, index) -> 
    ( if(isSalesChannelValid(item.SalesChannel[0]) and isSPSNotExpired(item.SaleExpirationDate[0]))
        item.ProductSpecID[0]
      else ""
    )
) filter ((item) -> !isEmpty(item))) default []
var attRef = variantAtomSpec.AttributesRef
var brandName = trim((attRef attRefValue "Brand_BCC") default "Not Found")
var masterGroupName = lower(brandName ++ "-" ++ specialCharMapping(modelName)) replace " " with "-"
var orderingCategory = (specIds reduce (item, acc = []) -> (acc ++ (vars.orderingCategory[item] default []))) distinctBy $
---
catalog @("xmlns": "http://www.demandware.com/xml/impex/catalog/2006-10-31", "catalog-id": "optus-master-catalog"): {
    product @("product-id": masterGroupName): {
        "display-name" @("xml:lang": "x-default"): modelName,
        "available-flag": "true",
        "searchable-flag": "true",
        "custom-attributes": {
            "custom-attribute" @("attribute-id": "productSpecId"): masterGroupName,
            "custom-attribute" @("attribute-id": "productCode"): masterGroupName,
            "custom-attribute" @("attribute-id": "productType"): "SIMPLE_PRODUCT",
            "custom-attribute" @("attribute-id": "simpleProductId"): payload.AtomicProductSpecification[0].ID,
            "custom-attribute" @("attribute-id": "orderingCategory"): {
            	value: orderingCategory
            },
            (allowedAttributes map (attr) -> {
                "custom-attribute" @("attribute-id": trim(attr)): (
                    // WIZ-164 use Digital_Model_BCC for watches
                    if (trim(attr) == "Model_BCC")
                        do {
                            var modelBCC = trim(attRef attRefValue "Model_BCC")
                            var digitalModelBCC = trim(attRef attRefValue "Digital_Model_BCC")
                            ---
                            if ((orderingCategory contains "Postpaid Watches") and ! isEmpty(digitalModelBCC))
                                digitalModelBCC
                            else
                                modelBCC
                        }
                    else
                       trim(attRef attRefValue attr)
                )
            }),
        },
        "variations": {
            "attributes": {( variationAttributesList map (masterAttr) -> 
                ("variation-attribute" @("attribute-id": masterAttr, "variation-attribute-id": masterAttr): {
                    //OD-1487 Added merge mode
                    "variation-attribute-values" @("merge-mode":"add"): {( getMasterAttributes(modelGroup,masterAttr) map (attrVal) ->
                        "variation-attribute-value" @(value: trim(attrVal)): {
                            "display-value" @("xml:lang": "x-default"): trim(attrVal)
                     	}
                	)},
            	}) 
                //WIZ-164 Remove null and N/A attributes
                filterObject (! isEmpty($."variation-attribute-values"."variation-attribute-value".@value))
        	)},
        	//OD-1487 Added merge mode
            "variants" @("merge-mode":"add"): {( specIds map (specId) -> 
                "variant" @("product-id": specId): null
            )}
	 	},
        "classification-category" @("catalog-id": "optus-au-storefront-catalog"): "mobile-device"
  	}
}