%dw 2.0
output application/json
---
flatten(flatten(vars.filteredOCArr.*CategoryRef).ProductRef).*ProductSpecID distinctBy $