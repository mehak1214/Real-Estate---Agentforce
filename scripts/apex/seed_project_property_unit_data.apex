// Seed Property__c and Unit__c data for the existing projects.
// Run with:
// sf apex run --file scripts/apex/seed_project_property_unit_data.apex --target-org <alias>

Set<String> targetProjectNames = new Set<String>{ 'Skyline Heights', 'Damac Lagoons' };

List<Project__c> projectRows = [
    SELECT Id, Name
    FROM Project__c
    WHERE Name IN :targetProjectNames
];

Map<String, Project__c> projectByName = new Map<String, Project__c>();
for (Project__c projectRow : projectRows) {
    projectByName.put(projectRow.Name, projectRow);
}

System.assertEquals(
    targetProjectNames.size(),
    projectByName.size(),
    'Expected both Skyline Heights and Damac Lagoons to exist before seeding Property__c and Unit__c data.'
);

Map<Id, Map<String, Property__c>> existingPropertiesByProject = new Map<Id, Map<String, Property__c>>();
for (Project__c projectRow : projectRows) {
    existingPropertiesByProject.put(projectRow.Id, new Map<String, Property__c>());
}

for (Property__c propertyRow : [
    SELECT Id, Name, Project_Inv__c, Property_Name_BF__c
    FROM Property__c
    WHERE Project_Inv__c IN :projectByName.values()
]) {
    if (!existingPropertiesByProject.containsKey(propertyRow.Project_Inv__c)) {
        existingPropertiesByProject.put(propertyRow.Project_Inv__c, new Map<String, Property__c>());
    }
    existingPropertiesByProject.get(propertyRow.Project_Inv__c).put(propertyRow.Property_Name_BF__c, propertyRow);
}

List<Property__c> propertiesToInsert = new List<Property__c>();
List<String> propertyKeysToAdd = new List<String>();
Map<String, Property__c> propertyByKey = new Map<String, Property__c>();

for (Project__c projectRow : projectRows) {
    List<String> propertyNames = new List<String>{
        projectRow.Name + ' Residences A',
        projectRow.Name + ' Residences B'
    };

    List<String> propertyTypes = new List<String>{ 'Luxury', 'Normal' };
    List<String> propertyDescriptions = new List<String>{
        'Seeded property for ' + projectRow.Name + ' block A',
        'Seeded property for ' + projectRow.Name + ' block B'
    };

    for (Integer i = 0; i < propertyNames.size(); i++) {
        String propertyName = propertyNames[i];
        String propertyKey = String.valueOf(projectRow.Id) + '|' + propertyName;

        if (existingPropertiesByProject.containsKey(projectRow.Id) && existingPropertiesByProject.get(projectRow.Id).containsKey(propertyName)) {
            propertyByKey.put(propertyKey, existingPropertiesByProject.get(projectRow.Id).get(propertyName));
            continue;
        }

        Property__c propertyRecord = new Property__c();
        propertyRecord.Name = propertyName;
        propertyRecord.Project_Inv__c = projectRow.Id;
        propertyRecord.Property_Name_BF__c = propertyName;
        propertyRecord.Property_Type__c = propertyTypes[i];
        propertyRecord.Type_of_Property__c = propertyDescriptions[i];
        propertyRecord.Description__c = propertyDescriptions[i];
        propertiesToInsert.add(propertyRecord);
        propertyKeysToAdd.add(propertyKey);
    }
}

if (!propertiesToInsert.isEmpty()) {
    insert propertiesToInsert;
    for (Integer i = 0; i < propertiesToInsert.size(); i++) {
        propertyByKey.put(propertyKeysToAdd[i], propertiesToInsert[i]);
    }
}

Map<Id, Map<String, Unit__c>> existingUnitsByProperty = new Map<Id, Map<String, Unit__c>>();
for (Property__c propertyRow : propertyByKey.values()) {
    existingUnitsByProperty.put(propertyRow.Id, new Map<String, Unit__c>());
}

List<Id> propertyIds = new List<Id>();
for (Property__c propertyRow : propertyByKey.values()) {
    propertyIds.add(propertyRow.Id);
}

for (Unit__c unitRow : [
    SELECT Id, Name, Property__c, Project__c, Status__c, Typology__c
    FROM Unit__c
    WHERE Property__c IN :propertyIds
]) {
    if (!existingUnitsByProperty.containsKey(unitRow.Property__c)) {
        existingUnitsByProperty.put(unitRow.Property__c, new Map<String, Unit__c>());
    }
    existingUnitsByProperty.get(unitRow.Property__c).put(unitRow.Name, unitRow);
}

List<Unit__c> unitsToInsert = new List<Unit__c>();

List<String> unitStatuses = new List<String>{ 'Available', 'Sold' };
List<String> unitTypologies = new List<String>{ '1 BED', '2 BED', '3 BED', '4 BHK' };

for (Project__c projectRow : projectRows) {
    List<Property__c> projectProperties = new List<Property__c>();
    for (Property__c propertyRow : propertyByKey.values()) {
        if (propertyRow.Project_Inv__c == projectRow.Id) {
            projectProperties.add(propertyRow);
        }
    }

    for (Property__c propertyRow : projectProperties) {
        for (Integer i = 1; i <= 4; i++) {
            String unitName = propertyRow.Property_Name_BF__c + ' Unit ' + String.valueOf(i);
            String unitKey = String.valueOf(propertyRow.Id) + '|' + unitName;

            if (existingUnitsByProperty.containsKey(propertyRow.Id) && existingUnitsByProperty.get(propertyRow.Id).containsKey(unitName)) {
                continue;
            }

            Unit__c unitRecord = new Unit__c();
            unitRecord.Name = unitName;
            unitRecord.Project__c = projectRow.Id;
            unitRecord.Property__c = propertyRow.Id;
            unitRecord.Status__c = unitStatuses[Math.mod(i - 1, unitStatuses.size())];
            unitRecord.Typology__c = unitTypologies[Math.mod(i - 1, unitTypologies.size())];
            unitRecord.Unit_Cost__c = 8500000 + (i * 250000) + (projectRow.Name == 'Damac Lagoons' ? 500000 : 0);
            unitsToInsert.add(unitRecord);
        }
    }
}

if (!unitsToInsert.isEmpty()) {
    insert unitsToInsert;
}

System.debug(
    LoggingLevel.WARN,
    'Seed complete. Projects=' + projectRows.size() +
    ', Properties=' + propertiesToInsert.size() +
    ', Units=' + unitsToInsert.size()
);