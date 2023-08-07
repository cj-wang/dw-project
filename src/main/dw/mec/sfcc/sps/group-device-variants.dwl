%dw 2.0
output application/json
//first grouping based on Brand ; Brand_BCC
var atomicProductSpecifications = payload
fun attRefValue(loc, strArg) = ((loc filter $.Item[0] == strArg)[0].Default) default "Not Found"
---
(atomicProductSpecifications groupBy (item) -> (
    // WIZ-164 use Digital_Model_BCC for watches
    do {
        var modelBCC = attRefValue(item.AtomicProductSpecification[0].AttributesRef, "Model_BCC")
        var digitalModelBCC = attRefValue(item.AtomicProductSpecification[0].AttributesRef, "Digital_Model_BCC")
        var orderingCategory = vars.orderingCategory[item.AtomicProductSpecification[0].ProductSpecID] default []
        ---
        if ((orderingCategory contains "Postpaid Watches") and ! isEmpty(digitalModelBCC))
            digitalModelBCC
        else
            modelBCC
    }
)) pluck (($$): $)