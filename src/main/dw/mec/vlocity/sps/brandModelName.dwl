%dw 2.0 
output application/json

fun specialCharMapping(strToUpdate) =  if(strToUpdate contains "\"") strToUpdate replace  ("\"") with "-inch"
                             else if (strToUpdate contains "'") strToUpdate replace  ("'") with "-"
                             else if (strToUpdate contains "\\") strToUpdate replace ("\\") with "-"
                             else if (strToUpdate contains "+") strToUpdate replace ("+") with "-plus"
                             else if (strToUpdate contains "<") strToUpdate replace ("<") with "-less"
                             else if (strToUpdate contains ">") strToUpdate replace (">") with "-greater"
                             else if (strToUpdate contains "&") strToUpdate replace ("&") with "-"
                             else strToUpdate

fun formatStr(strToUpdate) = do {
    var loweredStr = lower(strToUpdate)
    var trimmedStr = trim(loweredStr)
    var specialCharMappingStr = specialCharMapping(trimmedStr)
    var removedSpaceStr = specialCharMappingStr replace " " with "-"
    ---
    removedSpaceStr
}

fun getModelBrandName() = do { 
    var modelBrandAttribArr = flatten(payload.AtomicProductSpecification.AttributesRef) filter ((item, index) -> ["Model_BCC", "Brand_BCC"] contains item.Item[0])
    var modelBrandAttribObj = {
        "Model_BCC": formatStr((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Model_BCC"))[0].Default),
        "Brand_BCC": formatStr((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Brand_BCC"))[0].Default)
    }
    var notWatch = ! (lower(modelBrandAttribObj.Model_BCC) contains "watch")
    var Digital_Model_BCC = formatStr((payload.AtomicProductSpecification[0].AttributesRef filter ($.Item[0] == "Digital_Model_BCC")) [0].Default) default null
    ---
    {
    	"Model_BCC": 
            if (notWatch or isEmpty(Digital_Model_BCC))
                trim((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Model_BCC"))[0].Default)
            else
                Digital_Model_BCC,
    	"Brand_BCC": trim((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Brand_BCC"))[0].Default),
    	brandModelNameStr: 
            if (notWatch or isEmpty(Digital_Model_BCC))
                lower(modelBrandAttribObj.Brand_BCC) ++ "-" ++ lower(modelBrandAttribObj.Model_BCC)
            else
                lower(modelBrandAttribObj.Brand_BCC) ++ "-" ++ lower(Digital_Model_BCC)
    }
}
---
getModelBrandName()