%dw 2.0
output application/json
import * from dw::util::Values
fun attRefValue(loc, strArg) = ((loc filter $.Item[0] == strArg)[0].Default) default "Not Found"
var AtomicProductSpecifications = payload.AtomicProductSpecifications
var filteredProdSpecs = AtomicProductSpecifications filter (
    (attRefValue($.AtomicProductSpecification[0].AttributesRef, "Device_Type_BCC") == "Mobile") 
        or
    (attRefValue($.AtomicProductSpecification[0].AttributesRef, "Device_Type_BCC") == "Mobile Broadband")
)
---
filteredProdSpecs