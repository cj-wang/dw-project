%dw 2.0
output application/xml

fun attRefValue(loc, strArg) = (loc filter $.Item[0] == strArg)[0].Default
fun getAllowedVarAttributes(model: String, attrList: Object) = attrList[model] default attrList["default"]

var dispName = payload.Name
var variantAtomSpec = payload.AtomicProductSpecification[0]
var allowedAttributes = vars.allowedAttributes default []
var variationAttributesList = vars.variationAttributes default []

var variantId = (variantAtomSpec.ProductSpecID default "")

var orderingCategory = vars.orderingCategory[variantId] default []

var attRef = variantAtomSpec.AttributesRef
var model = do {
    // WIZ-164 use Digital_Model_BCC for watches
    var modelBCC = attRef attRefValue "Model_BCC"
    var digitalModelBCC = attRef attRefValue "Digital_Model_BCC"
    ---
    if ((orderingCategory contains "Postpaid Watches") and ! isEmpty(digitalModelBCC))
        digitalModelBCC
    else
        modelBCC
}
// var allowedVariantAttr = getAllowedVarAttributes(model, variationAttributesList) default []
var allowedVariantAttr = ["Color_BCC", "Internal_Memory_BCC", "Screen_Size_BCC", "Band_Type_BCC", "Band_Size_BCC", "Band_Colour_BCC"]

var completeAttr = flatten(attRef.Item) orderBy $
var dynamicProdAttr = if(!isEmpty(allowedAttributes)) (completeAttr filter (attr) ->  allowedAttributes contains attr)  else completeAttr
var dynamicCustAttr = completeAttr filter (attr) -> allowedVariantAttr contains attr

var fixedCustomAttributes = {
    "Brand_BCC": (attRef filter $.Item[0] == "Brand_BCC")[0].Default,
    "Device_Name_BCC": (attRef filter $.Item[0] == "Device_Name_BCC")[0].Default,
    "Device_Type_BCC": (attRef filter $.Item[0] == "Device_Type_BCC")[0].Default,
    "Equipment_Type_BCC": (attRef filter $.Item[0] == "Equipment_Type_BCC")[0].Default,
    "Model_BCC": model,
    "SKU_Type_BCC": (if(!isEmpty((attRef filter $.Item[0] == "SKU_Type_BCC")[0].Default)) (attRef filter $.Item[0] == "SKU_Type_BCC")[0].Default else "Standalone")
}
---
{
  catalog @(xmlns: "http://www.demandware.com/xml/impex/catalog/2006-10-31", "catalog-id": "optus-master-catalog"): {
    product @("product-id": trim(variantId)): {
      "display-name" @("xml:lang": "x-default"): dispName,
      "available-flag": "true",
      "searchable-flag": "true",
      "custom-attributes": {
        // Static Attributes
        "custom-attribute" @("attribute-id": "productType"): "SIMPLE_PRODUCT",
        "custom-attribute" @("attribute-id": "productCode"): trim(variantAtomSpec.Code),
        "custom-attribute" @("attribute-id": "productSpecId"): trim(variantId),
         "custom-attribute" @("attribute-id": "simpleProductId"): payload.AtomicProductSpecification[0].ID,
        "custom-attribute" @("attribute-id": "productSKU"): trim(attRefValue(attRef,"SKU_BCC")),
        "custom-attribute" @("attribute-id": "Brand_BCC"): fixedCustomAttributes.Brand_BCC,
        "custom-attribute" @("attribute-id": "Device_Name_BCC"):fixedCustomAttributes.Device_Name_BCC,
        "custom-attribute" @("attribute-id": "Device_Type_BCC"):fixedCustomAttributes.Device_Type_BCC,
        "custom-attribute" @("attribute-id": "Equipment_Type_BCC"):fixedCustomAttributes.Equipment_Type_BCC,
        "custom-attribute" @("attribute-id": "Model_BCC"):fixedCustomAttributes.Model_BCC,
        "custom-attribute" @("attribute-id": "SKU_Type_BCC"): fixedCustomAttributes.SKU_Type_BCC,
        "custom-attribute" @("attribute-id": "orderingCategory"): {
        	"value": orderingCategory
        },
        // Dynamic Attributes
        (dynamicCustAttr map (attr) -> {
            "custom-attribute" @("attribute-id": trim(attr)): trim(attRefValue(attRef, attr))
        }),
        "custom-attribute" @("attribute-id": "productAttributes"): {
            value: (dynamicProdAttr map (attr) -> (
                if(!isEmpty(attRefValue(attRef, attr)) and (attRefValue(attRef, attr) != "N/A"))
                trim(attr) ++ ":" ++ (
                    if (trim(attr) == "Model_BCC")
                        model
                    else
                        trim(attRefValue(attRef, attr))
                )
                else
                {}
            )) filter !isEmpty($)
        }
      },
      "classification-category" @("catalog-id": "optus-au-storefront-catalog"): "mobile-device"
    }
  }
}