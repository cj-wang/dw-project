%dw 2.0
import * from dw::util::Values
output application/json

fun specialCharMapping(strToUpdate) =  if(strToUpdate contains "\"") strToUpdate replace  ("\"") with "-inch"
                             else if (strToUpdate contains "'") strToUpdate replace  ("'") with "-"
                             else if (strToUpdate contains "\\") strToUpdate replace ("\\") with "-"
                             else if (strToUpdate contains "+") strToUpdate replace ("+") with "-plus"
                             else if (strToUpdate contains "<") strToUpdate replace ("<") with "-less"
                             else if (strToUpdate contains ">") strToUpdate replace (">") with "-greater"
                             else if (strToUpdate contains "&") strToUpdate replace ("&") with "-"
                             else strToUpdate

fun getAttributesRefArr() = do {
    var allowedAttribs = ["Device_Type_BCC", "Brand_BCC", "Model_BCC"]
    fun getAllowedAttribs() = payload.AtomicProductSpecification[0].AttributesRef filter ((item, index) -> allowedAttribs contains item.Item[0])
    ---
    getAllowedAttribs() reduce ((item, accumulator={}) 
        -> accumulator ++ ((item.Item[0]): item.Default default null))
}

var Digital_Model_BCC = (payload.AtomicProductSpecification[0].AttributesRef filter ($.Item[0] == "Digital_Model_BCC")) [0].Default default null

var attributesRefRes = [
    if (vars.notWatch or isEmpty(Digital_Model_BCC))
        getAttributesRefArr()
    else
        getAttributesRefArr() update {
            case .Model_BCC -> Digital_Model_BCC
        }
]
---
{
	"SimpleProductSpecName": vars.brandModelName.brandModelNameStr,
	"AttributesRef": attributesRefRes
	
}