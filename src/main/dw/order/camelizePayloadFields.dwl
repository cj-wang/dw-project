%dw 2.0
import * from dw::core::Strings
fun formatAllValues(inputVal="", formatter) = 
	inputVal match {
	case is Array ->  inputVal map (value,index) -> formatAllValues(value, formatter)
	case is Object -> inputVal mapObject (value,key) -> {
		(formatter(key)) : formatAllValues (value, formatter)
	}
        case is String -> inputVal
        else -> inputVal
}
output application/json
---
formatAllValues(payload, (str) -> camelize(underscore(str)))