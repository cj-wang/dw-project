%dw 2.0 
output application/json

fun getPostpaidTabletsAndMobilePhones() = payload.OrderingCategory filter ((item, index)-> (item.Name == "Postpaid Mobile Phones") or (item.Name == "Postpaid Tablets") or (item.Name == "Postpaid Watches"))

var filteredOCJson = getPostpaidTabletsAndMobilePhones()
---
filteredOCJson map ((item) -> {
    "Name": item.Name,
    "CategoryRef": item.CategoryRef map ((catRef) -> {
        "ID": catRef.ID,
        "Description": catRef.Description,
        "Code": catRef.Code,
        "ProductOfferingRef": catRef.ProductOfferingRef,
        "ProductRef": catRef.ProductRef map ((prodRef) -> {
            "Name": prodRef.Name,
            "Code": prodRef.Code[0],
            "ProductSpecID": prodRef.ProductSpecID[0],
            "ProductOfferingID": prodRef.ProductOfferingID[0]
        })
    })
})