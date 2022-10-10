%dw 2.0
output application/json
---
{
    "OrderId": vars.cartId,
    "OrderItemId": payload[0].Id,
    "BaseplanBOID": vars.originalPayload.fixedBroadband[0].itemId,
    "ContractDuration": vars.originalPayload.fixedBroadband[0].contractDuration,
    "InstallationMethod": vars.originalPayload.fixedBroadband[0].installationMethod,
    "NetworkTechnology": vars.originalPayload.fixedBroadband[0].networkTechnology,
    "AddressMatchType": vars.originalPayload.fixedBroadband[0].addressMatchType,
	"ChargeZone": vars.originalPayload.fixedBroadband[0].chargeZone,
	"CVCID": vars.originalPayload.fixedBroadband[0].cvcId,
	"GnafID": vars.originalPayload.fixedBroadband[0].gnafId,
	"NBNLocationID": vars.originalPayload.fixedBroadband[0].nbnLocationId,
	"NBNNewDevelopmentCharge": vars.originalPayload.fixedBroadband[0].nbnDevChargeFlag,
	"NTDID": vars.originalPayload.fixedBroadband[0].nbnNtdId,
	"NTDLocationID": vars.originalPayload.fixedBroadband[0].nbnNtdLocationId,
	"NTDPortID": vars.originalPayload.fixedBroadband[0].nbnPortId,
	"NTDType": vars.originalPayload.fixedBroadband[0].nbnNtdType,
	"TESA": vars.originalPayload.fixedBroadband[0].tesa,
	"New_line_consent_Flag_BCC": vars.originalPayload.fixedBroadband[0].New_line_consent_Flag_BCC,
    "Copper_Pair_ID_BCC": vars.originalPayload.fixedBroadband[0].Copper_Pair_ID_BCC,
    "AuthorityFlag": vars.originalPayload.fixedBroadband[0].Authority_Flag_BCC,
    "MaximumDownloadSpeed": vars.originalPayload.fixedBroadband[0].Maximum_Download_Speed,
	"MaximumUploadSpeed": vars.originalPayload.fixedBroadband[0].Maximum_Upload_Speed,
	"BYOModem": {
		"true": "Y",
		"false": "N"
	} [vars.originalPayload.fixedBroadband[0].BYODSelected] default null,
	"BYODIndicator": {
		"true": "Yes",
		"false": "No"
	} [vars.originalPayload.fixedBroadband[0].BYODSelected] default null
}