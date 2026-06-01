// Seed Module__c data for the existing projects.
// Run with:
// sf apex run --file scripts/apex/seed_module_data.apex --target-org <alias>

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
    'Expected both Skyline Heights and Damac Lagoons to exist before seeding Module__c data.'
);

Map<String, Id> moduleRecordTypeIds = new Map<String, Id>{
    'Tower' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Tower').getRecordTypeId(),
    'Wing' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Wing').getRecordTypeId(),
    'Floor' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Floor').getRecordTypeId(),
    'Unit' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Unit').getRecordTypeId(),
    'Amenities' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Amenities').getRecordTypeId(),
    'Specifications' => Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Specifications').getRecordTypeId()
};

List<Module__c> existingModules = [
    SELECT Id, Project__c, RecordType.Name, Tower__c, Wing__c, Floor__c,
           Tower_Name__c, Wing_Name__c, Floor_Name__c, Unit_Name__c,
           Amenity_Title__c, Specification_Title__c, Record_Type_Name__c
    FROM Module__c
    WHERE Project__c IN :projectByName.values()
];

Map<String, Module__c> moduleByKey = new Map<String, Module__c>();
for (Module__c moduleRow : existingModules) {
    String recordTypeName = moduleRow.RecordType.Name;
    String key;

    if (recordTypeName == 'Tower') {
        key = String.valueOf(moduleRow.Project__c) + '|Tower|' + moduleRow.Tower_Name__c;
    } else if (recordTypeName == 'Wing') {
        key = String.valueOf(moduleRow.Project__c) + '|Wing|' + String.valueOf(moduleRow.Tower__c) + '|' + moduleRow.Wing_Name__c;
    } else if (recordTypeName == 'Floor') {
        key = String.valueOf(moduleRow.Project__c) + '|Floor|' + String.valueOf(moduleRow.Tower__c) + '|' + String.valueOf(moduleRow.Wing__c) + '|' + String.valueOf(moduleRow.Floor_Name__c);
    } else if (recordTypeName == 'Unit') {
        key = String.valueOf(moduleRow.Project__c) + '|Unit|' + String.valueOf(moduleRow.Tower__c) + '|' + String.valueOf(moduleRow.Wing__c) + '|' + String.valueOf(moduleRow.Floor__c) + '|' + moduleRow.Unit_Name__c;
    } else if (recordTypeName == 'Amenities') {
        key = String.valueOf(moduleRow.Project__c) + '|Amenities|' + moduleRow.Amenity_Title__c;
    } else if (recordTypeName == 'Specifications') {
        key = String.valueOf(moduleRow.Project__c) + '|Specifications|' + moduleRow.Specification_Title__c;
    }

    if (key != null) {
        moduleByKey.put(key, moduleRow);
    }
}

List<Module__c> towersToInsert = new List<Module__c>();
List<String> towerKeysToAdd = new List<String>();
Map<String, Module__c> towerByKey = new Map<String, Module__c>(moduleByKey);

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;

    List<String> towerNames = new List<String>{
        projectName + ' Tower A',
        projectName + ' Tower B'
    };
    List<Boolean> towerHasWings = new List<Boolean>{ true, false };
    List<String> towerCategories = new List<String>{ 'Luxury', 'Prime' };

    for (Integer towerIndex = 0; towerIndex < towerNames.size(); towerIndex++) {
        String towerName = towerNames[towerIndex];
        String towerKey = String.valueOf(projectId) + '|Tower|' + towerName;

        if (towerByKey.containsKey(towerKey)) {
            continue;
        }

        Module__c tower = new Module__c();
        tower.RecordTypeId = moduleRecordTypeIds.get('Tower');
        tower.Project__c = projectId;
        tower.Record_Type_Name__c = 'Tower';
        tower.Tower_Name__c = towerName;
        tower.has_wing__c = towerHasWings[towerIndex];
        tower.Category__c = towerCategories[towerIndex];
        tower.Unit_Status__c = 'Available';
        tower.Unit_Type__c = 'Unit Block';
        tower.Vastu__c = 'North';
        tower.Facing__c = towerIndex == 0 ? 'North' : 'East';
        tower.Unit_Size__c = towerIndex == 0 ? '3 BHK' : '2 BHK';
        towersToInsert.add(tower);
        towerKeysToAdd.add(towerKey);
    }
}

if (!towersToInsert.isEmpty()) {
    insert towersToInsert;
    for (Integer i = 0; i < towersToInsert.size(); i++) {
        towerByKey.put(towerKeysToAdd[i], towersToInsert[i]);
    }
}

List<Module__c> wingsToInsert = new List<Module__c>();
List<String> wingKeysToAdd = new List<String>();
Map<String, Module__c> wingByKey = new Map<String, Module__c>(moduleByKey);

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;
    Module__c towerA = towerByKey.get(String.valueOf(projectId) + '|Tower|' + projectName + ' Tower A');

    if (towerA != null) {
        for (String wingName : new List<String>{ 'Wing 1', 'Wing 2' }) {
            String wingKey = String.valueOf(projectId) + '|Wing|' + String.valueOf(towerA.Id) + '|' + wingName;

            if (wingByKey.containsKey(wingKey)) {
                continue;
            }

            Module__c wing = new Module__c();
            wing.RecordTypeId = moduleRecordTypeIds.get('Wing');
            wing.Project__c = projectId;
            wing.Tower__c = towerA.Id;
            wing.Record_Type_Name__c = 'Wing';
            wing.Wing_Name__c = wingName;
            wing.Category__c = 'Luxury';
            wing.Unit_Status__c = 'Available';
            wing.Unit_Type__c = 'Unit Block';
            wing.Vastu__c = 'North';
            wing.Facing__c = wingName == 'Wing 1' ? 'North' : 'East';
            wing.Unit_Size__c = '3 BHK';
            wingsToInsert.add(wing);
            wingKeysToAdd.add(wingKey);
        }
    }
}

if (!wingsToInsert.isEmpty()) {
    insert wingsToInsert;
    for (Integer i = 0; i < wingsToInsert.size(); i++) {
        wingByKey.put(wingKeysToAdd[i], wingsToInsert[i]);
    }
}

List<Module__c> floorsToInsert = new List<Module__c>();
List<String> floorKeysToAdd = new List<String>();
Map<String, Module__c> floorByKey = new Map<String, Module__c>(moduleByKey);

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;
    Module__c towerA = towerByKey.get(String.valueOf(projectId) + '|Tower|' + projectName + ' Tower A');
    Module__c towerB = towerByKey.get(String.valueOf(projectId) + '|Tower|' + projectName + ' Tower B');

    if (towerA != null) {
        for (String wingName : new List<String>{ 'Wing 1', 'Wing 2' }) {
            Module__c wing = wingByKey.get(String.valueOf(projectId) + '|Wing|' + String.valueOf(towerA.Id) + '|' + wingName);

            if (wing == null) {
                continue;
            }

            for (Integer floorNo = 1; floorNo <= 2; floorNo++) {
                String floorKey = String.valueOf(projectId) + '|Floor|' + String.valueOf(towerA.Id) + '|' + String.valueOf(wing.Id) + '|' + String.valueOf(floorNo);

                if (floorByKey.containsKey(floorKey)) {
                    continue;
                }

                Module__c floor = new Module__c();
                floor.RecordTypeId = moduleRecordTypeIds.get('Floor');
                floor.Project__c = projectId;
                floor.Tower__c = towerA.Id;
                floor.Wing__c = wing.Id;
                floor.Record_Type_Name__c = 'Floor';
                floor.Floor_Name__c = floorNo;
                floor.Category__c = 'Luxury';
                floor.Unit_Status__c = 'Available';
                floor.Unit_Type__c = 'Unit Block';
                floor.Vastu__c = 'North';
                floor.Facing__c = 'North';
                floor.Unit_Size__c = '3 BHK';
                floorsToInsert.add(floor);
                floorKeysToAdd.add(floorKey);
            }
        }
    }

    if (towerB != null) {
        for (Integer floorNo = 1; floorNo <= 3; floorNo++) {
            String floorKey = String.valueOf(projectId) + '|Floor|' + String.valueOf(towerB.Id) + '|NONE|' + String.valueOf(floorNo);

            if (floorByKey.containsKey(floorKey)) {
                continue;
            }

            Module__c floor = new Module__c();
            floor.RecordTypeId = moduleRecordTypeIds.get('Floor');
            floor.Project__c = projectId;
            floor.Tower__c = towerB.Id;
            floor.Record_Type_Name__c = 'Floor';
            floor.Floor_Name__c = floorNo;
            floor.Category__c = 'Prime';
            floor.Unit_Status__c = 'Available';
            floor.Unit_Type__c = 'Unit Block';
            floor.Vastu__c = 'East';
            floor.Facing__c = 'East';
            floor.Unit_Size__c = '2 BHK';
            floorsToInsert.add(floor);
            floorKeysToAdd.add(floorKey);
        }
    }
}

if (!floorsToInsert.isEmpty()) {
    insert floorsToInsert;
    for (Integer i = 0; i < floorsToInsert.size(); i++) {
        floorByKey.put(floorKeysToAdd[i], floorsToInsert[i]);
    }
}

List<Module__c> unitsToInsert = new List<Module__c>();
List<String> unitKeysToAdd = new List<String>();

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;
    Module__c towerA = towerByKey.get(String.valueOf(projectId) + '|Tower|' + projectName + ' Tower A');
    Module__c towerB = towerByKey.get(String.valueOf(projectId) + '|Tower|' + projectName + ' Tower B');

    List<String> statuses = new List<String>{ 'Available', 'Hold', 'Booked', 'Sold', 'Refuge' };
    List<String> sizes = new List<String>{ '1 BHK', '2 BHK', '3 BHK', '4 BHK' };
    List<String> facings = new List<String>{ 'North', 'East', 'South', 'West' };
    List<String> vastus = new List<String>{ 'North', 'East', 'South', 'West' };

    if (towerA != null) {
        for (String wingName : new List<String>{ 'Wing 1', 'Wing 2' }) {
            Module__c wing = wingByKey.get(String.valueOf(projectId) + '|Wing|' + String.valueOf(towerA.Id) + '|' + wingName);
            if (wing == null) {
                continue;
            }

            for (Integer floorNo = 1; floorNo <= 2; floorNo++) {
                Module__c floor = floorByKey.get(String.valueOf(projectId) + '|Floor|' + String.valueOf(towerA.Id) + '|' + String.valueOf(wing.Id) + '|' + String.valueOf(floorNo));
                if (floor == null) {
                    continue;
                }

                for (Integer unitNo = 1; unitNo <= 2; unitNo++) {
                    String unitName = 'Unit ' + projectName.left(3).toUpperCase() + '-A' + wingName.right(1) + floorNo + unitNo;
                    String unitKey = String.valueOf(projectId) + '|Unit|' + String.valueOf(towerA.Id) + '|' + String.valueOf(wing.Id) + '|' + String.valueOf(floor.Id) + '|' + unitName;

                    if (moduleByKey.containsKey(unitKey)) {
                        continue;
                    }

                    Decimal carpetArea = 720 + (floorNo * 55) + (unitNo * 12);
                    Decimal totalPrice = carpetArea * 9500;
                    Decimal pricePerSqft = 9500;

                    Module__c unit = new Module__c();
                    unit.RecordTypeId = moduleRecordTypeIds.get('Unit');
                    unit.Project__c = projectId;
                    unit.Tower__c = towerA.Id;
                    unit.Wing__c = wing.Id;
                    unit.Floor__c = floor.Id;
                    unit.Record_Type_Name__c = 'Unit';
                    unit.Unit_Name__c = unitName;
                    unit.Unit_Status__c = statuses[Math.mod(unitNo + floorNo, statuses.size())];
                    unit.Unit_Size__c = sizes[Math.mod(floorNo + unitNo, sizes.size())];
                    unit.Unit_Type__c = 'Unit Block';
                    unit.Category__c = 'Luxury';
                    unit.Vastu__c = vastus[Math.mod(floorNo + unitNo, vastus.size())];
                    unit.Facing__c = facings[Math.mod(floorNo + unitNo, facings.size())];
                    unit.Carpet_Area__c = carpetArea;
                    unit.Total_Price__c = totalPrice;
                    unit.Price_Per_Sqft__c = pricePerSqft;
                    unit.Balcony__c = 45 + unitNo;
                    unit.Unit_Bedroom_Count__c = floorNo + unitNo;
                    unit.Unit_Bathroom_Count__c = unitNo + 1;
                    unit.Unit_Description__c = 'Seeded unit for ' + projectName + ', ' + wingName + ', floor ' + String.valueOf(floorNo);
                    unitsToInsert.add(unit);
                    unitKeysToAdd.add(unitKey);
                }
            }
        }
    }

    if (towerB != null) {
        for (Integer floorNo = 1; floorNo <= 3; floorNo++) {
            Module__c floor = floorByKey.get(String.valueOf(projectId) + '|Floor|' + String.valueOf(towerB.Id) + '|NONE|' + String.valueOf(floorNo));
            if (floor == null) {
                continue;
            }

            for (Integer unitNo = 1; unitNo <= 3; unitNo++) {
                String unitName = 'Unit ' + projectName.left(3).toUpperCase() + '-B' + floorNo + unitNo;
                String unitKey = String.valueOf(projectId) + '|Unit|' + String.valueOf(towerB.Id) + '|NONE|' + String.valueOf(floor.Id) + '|' + unitName;

                if (moduleByKey.containsKey(unitKey)) {
                    continue;
                }

                Decimal carpetArea = 610 + (floorNo * 42) + (unitNo * 10);
                Decimal totalPrice = carpetArea * 8200;
                Decimal pricePerSqft = 8200;

                Module__c unit = new Module__c();
                unit.RecordTypeId = moduleRecordTypeIds.get('Unit');
                unit.Project__c = projectId;
                unit.Tower__c = towerB.Id;
                unit.Floor__c = floor.Id;
                unit.Record_Type_Name__c = 'Unit';
                unit.Unit_Name__c = unitName;
                unit.Unit_Status__c = statuses[Math.mod(floorNo + unitNo + 1, statuses.size())];
                unit.Unit_Size__c = sizes[Math.mod(floorNo + unitNo + 1, sizes.size())];
                unit.Unit_Type__c = 'Unit Block';
                unit.Category__c = 'Prime';
                unit.Vastu__c = vastus[Math.mod(floorNo + unitNo + 1, vastus.size())];
                unit.Facing__c = facings[Math.mod(floorNo + unitNo + 1, facings.size())];
                unit.Carpet_Area__c = carpetArea;
                unit.Total_Price__c = totalPrice;
                unit.Price_Per_Sqft__c = pricePerSqft;
                unit.Balcony__c = 30 + unitNo;
                unit.Unit_Bedroom_Count__c = unitNo + 1;
                unit.Unit_Bathroom_Count__c = unitNo;
                unit.Unit_Description__c = 'Seeded unit for ' + projectName + ', floor ' + String.valueOf(floorNo);
                unitsToInsert.add(unit);
                unitKeysToAdd.add(unitKey);
            }
        }
    }
}

if (!unitsToInsert.isEmpty()) {
    insert unitsToInsert;
    for (Integer i = 0; i < unitsToInsert.size(); i++) {
        moduleByKey.put(unitKeysToAdd[i], unitsToInsert[i]);
    }
}

List<Module__c> amenitiesToInsert = new List<Module__c>();
List<String> amenityKeysToAdd = new List<String>();

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;
    List<String> amenityTitles = new List<String>{ 'Club House', 'Swimming Pool' };

    for (Integer i = 0; i < amenityTitles.size(); i++) {
        String amenityTitle = amenityTitles[i];
        String amenityKey = String.valueOf(projectId) + '|Amenities|' + amenityTitle;

        if (moduleByKey.containsKey(amenityKey)) {
            continue;
        }

        Module__c amenity = new Module__c();
        amenity.RecordTypeId = moduleRecordTypeIds.get('Amenities');
        amenity.Project__c = projectId;
        amenity.Record_Type_Name__c = 'Amenities';
        amenity.Amenity_Title__c = amenityTitle + ' - ' + projectName;
        amenity.Amenity_Description__c = '<p>Seeded amenity for ' + projectName + '.</p>';
        amenity.Amenity_Image__c = '<p>amenity-' + String.valueOf(i + 1) + '.png</p>';
        amenity.Amenity_Type__c = 'Amenity';
        amenity.Category__c = 'Luxury';
        amenitiesToInsert.add(amenity);
        amenityKeysToAdd.add(amenityKey);
    }
}

if (!amenitiesToInsert.isEmpty()) {
    insert amenitiesToInsert;
    for (Integer i = 0; i < amenitiesToInsert.size(); i++) {
        moduleByKey.put(amenityKeysToAdd[i], amenitiesToInsert[i]);
    }
}

List<Module__c> specificationsToInsert = new List<Module__c>();
List<String> specificationKeysToAdd = new List<String>();

for (String projectName : new List<String>{ 'Skyline Heights', 'Damac Lagoons' }) {
    Id projectId = projectByName.get(projectName).Id;
    List<String> specificationTitles = new List<String>{ 'Flooring', 'Kitchen Finishes' };

    for (Integer i = 0; i < specificationTitles.size(); i++) {
        String specificationTitle = specificationTitles[i];
        String specificationKey = String.valueOf(projectId) + '|Specifications|' + specificationTitle;

        if (moduleByKey.containsKey(specificationKey)) {
            continue;
        }

        Module__c specification = new Module__c();
        specification.RecordTypeId = moduleRecordTypeIds.get('Specifications');
        specification.Project__c = projectId;
        specification.Record_Type_Name__c = 'Specifications';
        specification.Specification_Title__c = specificationTitle + ' - ' + projectName;
        specification.Specification_Description__c = '<p>Seeded specification for ' + projectName + '.</p>';
        specification.Specification_Image__c = '<p>specification-' + String.valueOf(i + 1) + '.png</p>';
        specification.Category__c = 'Prime';
        specificationsToInsert.add(specification);
        specificationKeysToAdd.add(specificationKey);
    }
}

if (!specificationsToInsert.isEmpty()) {
    insert specificationsToInsert;
    for (Integer i = 0; i < specificationsToInsert.size(); i++) {
        moduleByKey.put(specificationKeysToAdd[i], specificationsToInsert[i]);
    }
}

System.debug(
    LoggingLevel.WARN,
    'Seed complete. Towers=' + towersToInsert.size() +
    ', Wings=' + wingsToInsert.size() +
    ', Floors=' + floorsToInsert.size() +
    ', Units=' + unitsToInsert.size() +
    ', Amenities=' + amenitiesToInsert.size() +
    ', Specifications=' + specificationsToInsert.size()
);