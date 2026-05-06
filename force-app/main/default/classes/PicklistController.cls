public without sharing class PicklistController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCountryOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            // Describe the field directly to get all picklist entries
            Schema.DescribeFieldResult fieldResult = BrokerApplication__c.RegisteredCountry__c.getDescribe();
            for(Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if(entry.isActive()) {
                    Map<String, String> option = new Map<String, String>();
                    option.put('label', entry.getLabel());
                    option.put('value', entry.getValue());
                    options.add(option);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching countries: ' + e.getMessage());
        }
        return options;
    }
}