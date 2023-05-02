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

fun formatStr(strToUpdate: String) = trim(lower(specialCharMapping(strToUpdate))) replace " " with "-"
		
fun getModelBrandName() = do { 
	    var modelBrandAttribArr = flatten(payload.AtomicProductSpecification.AttributesRef) filter ((item, index) -> ["Model_BCC", "Brand_BCC"] contains item.Item[0])
	    var modelBrandAttribObj = {
	        "Model_BCC": formatStr((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Model_BCC"))[0].Default),
	        "Brand_BCC": formatStr((modelBrandAttribArr filter ((item, index) -> item.Item[0] == "Brand_BCC"))[0].Default)
	    }
	    ---
	    lower(modelBrandAttribObj.Brand_BCC) ++ "-" ++ lower(modelBrandAttribObj.Model_BCC)
	}
fun getSpecAttributes() = do{
    var identifiedAttribNamesArr = ["Color_BCC", "Internal_Memory_BCC", "SKU_BCC", "Device_Name_BCC", "SIM_Type_BCC", "Screen_Size_BCC", "Band_Type_BCC", "Band_Size_BCC", "Band_Colour_BCC"]
    var filteredAttribArr = payload.AtomicProductSpecification[0].AttributesRef filter ((item, index) -> identifiedAttribNamesArr contains item.Item[0])
    ---
    filteredAttribArr reduce ((item, accumulator={}) 
        -> accumulator ++ ((item.Item[0]): item.Default default null))
}


var specAttribs = getSpecAttributes()
var attribValInput = if (vars.notWatch) (
    [
        specAttribs."Color_BCC",
        specAttribs."Internal_Memory_BCC"
    ] joinBy ";"
) else (
    [
        specAttribs."Color_BCC",
        specAttribs."Internal_Memory_BCC",
        specAttribs."Screen_Size_BCC",
        specAttribs."Band_Type_BCC",
        specAttribs."Band_Size_BCC",
        specAttribs."Band_Colour_BCC"
    ] joinBy ";"
)


var attribNameInput = if (vars.notWatch) (
    [
        (if(!isEmpty(specAttribs."Color_BCC")) "Color_BCC" else ""),
        (if(!isEmpty(specAttribs."Internal_Memory_BCC")) "Internal_Memory_BCC" else "")
    ] joinBy ";" 
) else (
    [
        (if(!isEmpty(specAttribs."Color_BCC")) "Color_BCC" else ""),
        (if(!isEmpty(specAttribs."Internal_Memory_BCC")) "Internal_Memory_BCC" else ""),
        (if(!isEmpty(specAttribs."Screen_Size_BCC")) "Screen_Size_BCC" else ""),
        (if(!isEmpty(specAttribs."Band_Type_BCC")) "Band_Type_BCC" else ""),
        (if(!isEmpty(specAttribs."Band_Size_BCC")) "Band_Size_BCC" else ""),
        (if(!isEmpty(specAttribs."Band_Colour_BCC")) "Band_Colour_BCC" else "")
    ] joinBy ";" 
)

var attribValOutput = [
	specAttribs."SKU_BCC",
	payload.AtomicProductSpecification[0].ProductSpecID,
	specAttribs."Device_Name_BCC"
] joinBy ";"

var attribNameOutput = [
	(if(!isEmpty(specAttribs."SKU_BCC")) "SKU_BCC" else ""),
	(if(!isEmpty(payload.AtomicProductSpecification[0].ProductSpecID)) "ProductSpecID" else ""),
	(if(!isEmpty(specAttribs."Device_Name_BCC")) "Device_Name_BCC" else "")
] joinBy ";"
---
{
   "SimpleProductSpecName": getModelBrandName(),
   "vlocity_cmt__InputData__c": {
   		"Attribute Value Input": attribValInput,
   		"Attribute Name Input": attribNameInput,
   		"Product Code": getModelBrandName()
   },
   "vlocity_cmt__OutputData__c": {
   		"Attribute Value Output": attribValOutput,
   		"Attribute Name Output": attribNameOutput
   },
   "SKU__c": specAttribs."SKU_BCC"
}