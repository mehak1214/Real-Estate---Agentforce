Dubai real estate CSV seed data.

Import order:
1. Project__c.csv
2. Property__c.csv
3. Unit__c.csv

Lookup mapping:
- Map `Project_Inv__c` on `Property__c` to `Project__c.Unique_External_Key__c`.
- Map `Project__c` and `Property__c` on `Unit__c` to the matching `Unique_External_Key__c` values.

The data is based on the existing Dubai projects Skyline Heights and Damac Lagoons.
