// SS order json uses duplicated keys, not array
%dw 2.0
output application/json
var xmlStringPayload = write(payload, 'application/xml')
var xmlStringPayloadReplace = xmlStringPayload replace '@' with '_____'
var objectPayload = read(xmlStringPayloadReplace, "application/xml")
var jsonStringPayload = write(objectPayload, 'application/json', {duplicateKeyAsArray: false})
var jsonStringPayloadReplace = jsonStringPayload replace '_____' with '@'
var resultObjectPayload = read(jsonStringPayloadReplace, 'application/json')
---
resultObjectPayload
