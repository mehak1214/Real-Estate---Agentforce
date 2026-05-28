public without sharing class LightningProjectInventoryController {

    // ================= WRAPPERS =================

    public class ProjectWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String location;

        @AuraEnabled public Decimal price;          // raw lowest price
        @AuraEnabled public String displayPrice;    // formatted lowest price

        @AuraEnabled public String status;
        @AuraEnabled public String image;
        @AuraEnabled public List<UnitWrapper> units;
    }

    public class UnitWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String unitNo;
        @AuraEnabled public String type;
        @AuraEnabled public Decimal area;

        @AuraEnabled public Decimal price;          // raw price
        @AuraEnabled public String displayPrice;    // formatted price

        @AuraEnabled public String status;
    }

    // ================= PRICE FORMATTER =================

    public static String formatPrice(Decimal value) {

        if (value == null) return '';

        if (value >= 10000000) {
            return '₹' + String.valueOf((value / 10000000).setScale(1)) + ' Cr';
        } 
        else if (value >= 100000) {
            return '₹' + String.valueOf((value / 100000).setScale(1)) + ' Lakh';
        } 
        else {
            return '₹' + String.valueOf(value.setScale(0));
        }
    }

    // ================= FETCH DATA =================

    @AuraEnabled(cacheable=true)
    public static List<ProjectWrapper> getProjectData() {

        List<Inventory_Assignment__c> records = [
            SELECT Id,
                   Unit__c,
                   Unit__r.Name,
                   Unit__r.Typology__c,
                //    Unit__r.Area_Square_Feet__c,
                //    Unit__r.Min_Proposed_Price__c,
                //    Unit__r.Unit_Status__c,
                    Unit__r.Project__r.Id,
                    Unit__r.Project__r.Name,
                    Unit__r.Project__r.Project_Status__c,
                    Unit__r.Project__r.Project_Location__c,
                    Unit__r.Project__r.Project_Image__c
            FROM Inventory_Assignment__c
           //WHERE Broker_Channel_Partner__c = '001Kh00001yYIHwIAO'
        ];

        Map<Id, ProjectWrapper> projectMap = new Map<Id, ProjectWrapper>();

        // ================= GROUPING =================

        for (Inventory_Assignment__c rec : records) {

            Id projId = rec.Unit__r.Project__r.Id;

            // CREATE PROJECT
            if (!projectMap.containsKey(projId)) {

                ProjectWrapper proj = new ProjectWrapper();
                proj.id = projId;
                proj.name = rec.Unit__r.Project__r.Name;
                //proj.location = rec.Unit__r.Project__r.Project_Location__c;
                proj.status = rec.Unit__r.Project__r.Project_Status__c;

                // // IMAGE (still text-based like "Tower1")
                proj.image = 'Tower1';
                    //rec.Unit__r.Project__r.Project_Image__c;

                proj.units = new List<UnitWrapper>();

                projectMap.put(projId, proj);
            }

            // ================= UNIT =================

            UnitWrapper unit = new UnitWrapper();
            unit.id = rec.Unit__c;
            unit.unitNo = rec.Unit__r.Name;
            // unit.type = rec.Unit__r.Flat_Type__c;
            // unit.area = rec.Unit__r.Area_Square_Feet__c;

            // unit.price = rec.Unit__r.Min_Proposed_Price__c;
            // unit.displayPrice = formatPrice(unit.price);

            // unit.status = rec.Unit__r.Unit_Status__c;

            projectMap.get(projId).units.add(unit);
        }

        // ================= LOWEST PRICE CALC =================

        for (ProjectWrapper proj : projectMap.values()) {

            Decimal minPrice = null;

            for (UnitWrapper u : proj.units) {
                if (u.price != null) {
                    if (minPrice == null || u.price < minPrice) {
                        minPrice = u.price;
                    }
                }
            }

            proj.price = minPrice;
            proj.displayPrice = formatPrice(minPrice);
        }

        return projectMap.values();
    }

    // ================= CREATE LEAD =================

    @AuraEnabled
    public static void createLead(String firstName, String lastName, String phone,
                                  String email, String budget,
                                  String project, String unit) {

        Lead ld = new Lead();
        ld.FirstName = firstName;
        ld.LastName = lastName;
        ld.Phone = phone;
        ld.Email = email;

        // UNIT ID
        ld.Unit__c = unit;

        //ld.Broker_Channel_Partner__c = '001Kh00001yYIHwIAO';
        //ld.Broker_Agent__c = '003Kh00001uWjqKIAS';

        insert ld;
    }
}