public with sharing class reimGetPicklistTypeFields {


    @AuraEnabled(cacheable=true)
	public static List<String> getProjectTypeValues() {
    Set<String> typeValues = new Set<String>();
    Schema.DescribeFieldResult fieldResult = Project__c.Project_Type__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry picklistVal : picklistValues) {
        typeValues.add(picklistVal.getLabel());
    }
    
    List<String> typeValuesLst=new List<String>(typeValues);
    typeValuesLst.add(0, 'All');
    system.debug('Project Type values: ' + typeValuesLst);
    return typeValuesLst;
}

    @AuraEnabled(cacheable=true)
    public static List<String> getProjectStatusValues() {
        List<String> statusValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Project__c.Project_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistVal : picklistValues) {
            statusValues.add(picklistVal.getLabel());
        }
 
		statusValues.add(0,'All');
        system.debug('Project Type values'+statusValues);
        return statusValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getDependentPicklistValues(String parentFieldName, String selectedParentValue, String dependentFieldName) {
        List<String> dependentValues = new List<String>();
        String soql = 'SELECT ' + dependentFieldName + ' FROM Project__c WHERE ' + parentFieldName + ' = \'' + selectedParentValue + '\'';
        List<Project__c> records = Database.query(soql);
        system.debug('Project Type values: ' + records);
        Set<String> sizeTypeValues = new Set<String>();
        for (Project__c record : records) {
            sizeTypeValues.add((String) record.get(dependentFieldName));
            system.debug('sizeTypeValues: ' + sizeTypeValues);
        }
        dependentValues.addAll(sizeTypeValues);
        system.debug('Project Type values: ' + dependentValues);
        return dependentValues;
}
    
     @AuraEnabled(cacheable=true)
    public static List<String> getProjectLocationValues() {
        List<Project__c> locationValues = [Select id, Project_Address__City__s from Project__c];
        List<String> locations=new List<String>();
        Map<String,Project__c> mapofLocationValues=new Map<String,Project__c>();

		for(Project__c loc:locationValues){
   	 	mapofLocationValues.put(loc.Project_Address__City__s,loc);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofLocationValues.keySet());
        locations.addAll(mapofLocationValues.keySet());
        locations.add(0,'All');
        System.debug(locations);
        return locations;
    }
    
    /*Dev:Sushant S
	  The Below code is written for Floor and Units page to fetch the option values for filters*/
     @AuraEnabled(cacheable=true)
    		public static List<Module__c> getTowersOptionsPerProject(String projId) {
         	List<Module__c> towerValues = new  List<Module__c>([Select Id,Tower_Name__c FROM Module__c where Project__c =:projId AND Record_Type_Name__c='Tower']);
        	system.debug(towerValues);
        	return towerValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getWingOptionsPerTowerOfProject(String towerId) {
        List<Module__c> wingValues = [Select Id,Wing_Name__c FROM Module__c where Tower__c =:towerId AND Record_Type_Name__c='Wing'];
        List<String> wings=new List<String>();
        Map<String,Module__c> mapofWingValues=new Map<String,Module__c>();

		for(Module__c mod : wingValues){
                mapofWingValues.put(mod.Wing_Name__c,mod);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofWingValues.keySet());
        wings.addAll(mapofWingValues.keySet());
        wings.add(0,'All');		//Adding 'All' value to the list
        System.debug(wings);
        return wings;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getUnitSizeOptionsPerTowerOfProject(String towerId) {
        List<Module__c> unitSizeValues = [Select Id,Tower__c, Unit_Size__c FROM Module__c where Tower__c =:towerId AND Record_Type_Name__c='Unit'];
        List<String> unitSize=new List<String>();
        Map<String,Module__c> mapofunitSizeValues=new Map<String,Module__c>();

		for(Module__c mod : unitSizeValues){
                mapofunitSizeValues.put(mod.Unit_Size__c ,mod);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofunitSizeValues.keySet());
        unitSize.addAll(mapofunitSizeValues.keySet());
        unitSize.add(0,'All');		//Adding 'All' value to the list
        System.debug(unitSize);
        return unitSize;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFacingOptionsPerTowerOfProject(String towerId) {
        List<Module__c> FacingValues = [Select Id,Tower__c, facing__c FROM Module__c where Tower__c =:towerId AND Record_Type_Name__c='Unit'];
        List<String> Facing=new List<String>();
        Map<String,Module__c> mapofFacingValues=new Map<String,Module__c>();

		for(Module__c mod : FacingValues){
                mapofFacingValues.put(mod.Facing__c ,mod);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofFacingValues.keySet());
        Facing.addAll(mapofFacingValues.keySet());
        Facing.add(0,'All');		//Adding 'All' value to the list
        System.debug(Facing);
        return Facing;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getVastuOptionsPerTowerOfProject(String towerId) {
        List<Module__c> vastuValues = [Select Id,Tower__c, vastu__c FROM Module__c where Tower__c =:towerId AND Record_Type_Name__c='Unit'];
        List<String> vastu=new List<String>();
        Map<String,Module__c> mapofVastuValues=new Map<String,Module__c>();

		for(Module__c mod : vastuValues){
                mapofVastuValues.put(mod.vastu__c ,mod);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofVastuValues.keySet());
        vastu.addAll(mapofVastuValues.keySet());
        vastu.add(0,'All');		//Adding 'All' value to the list
        System.debug(vastu);
        return vastu;
    }
    
        @AuraEnabled(cacheable=true)
    public static List<String> getUnitStatusPerTowerOfProject(String towerId) {
        List<Module__c> unitStatusValues = [Select Id,Tower__c, Unit_Status__c FROM Module__c where Tower__c =:towerId AND Record_Type_Name__c='Unit'];
        List<String> unitStatus=new List<String>();
        Map<String,Module__c> mapofunitStatusValues=new Map<String,Module__c>();

		for(Module__c mod : unitStatusValues){
                mapofunitStatusValues.put(mod.Unit_Status__c ,mod);//This is map and hence it will always have unique values 
		}
		system.debug('List return'+mapofunitStatusValues.keySet());
        unitStatus.addAll(mapofunitStatusValues.keySet());
        unitStatus.add(0,'All');		//Adding 'All' value to the list
        System.debug(unitStatus);
        return unitStatus;
    }
    
}