public class Reim_FilterFor_TowerAndFloors {
    /*Dev : Sushant S, Below 3 methods are used in 'Reim_showFloorAndUnits' Component*/
    	@AuraEnabled(cacheable=true)
    public static List<Module__c> getTowersDataUponFilter
		( String projId,String towerId,String wing, String SizeType,String Vastu, String Facing,String UnitStatus) {
			String query=' ';
            String query1=' ';
            if(wing == 'All' && SizeType == 'All' && Vastu == 'All' && Facing == 'All' && UnitStatus == 'All'){
               query1='Select Id, Project__c,  Record_Type_Name__c, Floor__c, Floor__r.Floor_Name__c, Tower__c,Tower__r.Tower_Name__c,Wing__c, Wing__r.Wing_Name__c, UniqueCode__c,Unit_Status__c, Unit_Name__c, Unit_Type__c,Vastu__c,Unit_Size__c,Facing__c from module__c WHERE Record_Type_Name__c=\'Unit\' AND Project__c=:projId AND Tower__c!=:towerId ';
            }
            else
            {
                query='Select Id, Project__c,  Record_Type_Name__c, Floor__c, Floor__r.Floor_Name__c, Tower__c,Tower__r.Tower_Name__c,Wing__c, Wing__r.Wing_Name__c, UniqueCode__c,Unit_Status__c, Unit_Name__c, Unit_Type__c,Vastu__c,Unit_Size__c,Facing__c from module__c WHERE (Record_Type_Name__c=\'Unit\' AND Project__c=:projId AND Tower__c=:towerId) AND (';
            }
            
		List<String> whereClauses = new List<String>();
            System.debug(query1.length());
            System.debug(query.length());
		if (wing != 'All') {
			whereClauses.add(' Wing__r.Wing_Name__c != :wing ');
		}
		if (SizeType != 'All') {
			whereClauses.add(' Unit_Size__c != :SizeType ');
		}
		if (Vastu != 'All') {
			whereClauses.add(' Vastu__c != :Vastu ');
		}
		if (Facing != 'All') {
			whereClauses.add(' Facing__c != :Facing ');
		}
		if (UnitStatus != 'All') {
			whereClauses.add(' Unit_Status__c != :UnitStatus ');
		}
            
        String condition=String.join(whereClauses, ' OR ');
            system.debug(condition);
            //System.debug(query);
            //System.debug(Database.query(query+condition));
            System.debug(query+condition);
            String resultQuery;
            if(query1.length()>=5){
                resultQuery= query1;
            }
            else if(query1.length()<=5){
                resultQuery=query+condition+')';
            }
             return Database.query(resultQuery);     
	}
    
        @AuraEnabled(cacheable=true)
    public static List<Module__c> getFloorsDataUponFilter( String towerId){
        List<Module__c> lstFloors=[Select id,Project__c,Tower__c,Floor_Name__c,has_wing__c from module__c where Tower__c=:towerId and Record_Type_Name__c='Floor' order by Floor_Name__c DESC];
        
        return lstFloors; 
    }
    
@AuraEnabled(cacheable=true)
    public static Map<String,List<Module__c>> getStaticUnitsDataToDisplay( String towerId){
        List<Module__c> lstUnits=[Select Id, Project__c,  Record_Type_Name__c, Floor__c, Floor__r.Floor_Name__c, Tower__c,Tower__r.Tower_Name__c,Wing__c, Wing__r.Wing_Name__c, UniqueCode__c,Unit_Status__c, Unit_Name__c, Unit_Type__c,Vastu__c,Unit_Size__c,Facing__c from module__c WHERE Record_Type_Name__c='Unit' AND Tower__c=:towerId order by Unit_Name__c DESC];
		System.debug(lstUnits);
        List<Module__c> floorList= Reim_FilterFor_TowerAndFloors.getFloorsDataUponFilter(towerId);
        System.debug(floorList);
     
        Map<String,List<Module__c>> mapUnits=new Map<String,List<Module__c>>();
        
        for(Module__c floors:floorList){
            List<Module__c> tempList=new List<Module__c>();
            for(Module__c units:lstUnits){
            	if(floors.Floor_Name__c==units.Floor__r.Floor_Name__c){ 
                	tempList.add(units);
            	}    
        }
           		mapUnits.put(String.valueOf(floors.id),tempList);
        }
        system.debug(mapUnits);
        return mapUnits; 
    }
    
    /*Dev : Sushant S, */
    @AuraEnabled(cacheable=true)
    public static String getTowerName( String towerId){
        List<Module__c> lstTowers=[Select id,Tower_Name__c from module__c where id=: towerId and Record_Type_Name__c='Tower'];
        String towerName;
        for(Module__c twr : lstTowers){
            towerName=twr.Tower_Name__c;
        }
        return towerName; 
    }
    
        @AuraEnabled(cacheable=true)
    public static Id getProjectId( String towerId){
        List<Module__c> lstTowers=[Select id,Tower_Name__c,Project__c from module__c where id=: towerId and Record_Type_Name__c='Tower'];
        Id projectId;
        for(Module__c twr : lstTowers){
            projectId= twr.Project__c;
        }
        system.debug(projectId);
        return projectId; 
    }
    
        @AuraEnabled(cacheable=true)
    public static Integer getAvailableUnitsPerTower( String towerId){
        return [Select count() FROM Module__c where Record_Type_Name__c='Unit' and tower__c=:towerId AND Unit_Status__c ='Available'];
    }
    
        @AuraEnabled(cacheable=true)
    public static List<Module__c> getUnitBluePrintData(String unitId) {
        List<Module__c> unitData = [Select Id,Tower__c,Unit_Name__c,Floor__r.Floor_Name__c,Unit_Size__c,Unit_Type__c,Unit_Plan_Image__c,Unit_Description__c, Unit_Bedroom_Count__c,Unit_Bathroom_Count__c,Total_Price__c, Price_Per_Sqft__c,Floor__r.Wing__r.Tower__r.Tower_Name__c,Unit_Status__c,Floor__r.Wing__r.Wing_Name__c,Carpet_Area__c, Balcony__c,Name,UniqueCode__c  
                        from Module__c where Id=: unitId AND Record_Type_Name__c='Unit'];
        
        System.debug('openUnit=====>' + unitData);
        return unitData;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getUnitsPerFloor_BluePrintData(String floorId) {
        List<Module__c> unitsData = [Select Id,Unit_Name__c,Floor__r.Floor_Name__c,Unit_Size__c,Unit_Type__c,Unit_Plan_Image__c,Unit_Description__c, Unit_Bedroom_Count__c,Unit_Bathroom_Count__c,Total_Price__c, Price_Per_Sqft__c,Floor__r.Wing__r.Tower__r.Tower_Name__c,Unit_Status__c,Floor__r.Wing__r.Wing_Name__c,Carpet_Area__c, Balcony__c 
                        from Module__c where Floor__c=: FloorId AND Record_Type_Name__c='Unit'];
        
        System.debug('openUnit=====>' + unitsData.size());
        return unitsData;      
    }
    
    @AuraEnabled(cacheable=true)
        public static Map<ID, String> getRelatedFilesByRecordId(String recordId) {
            // Get record file IDs        
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }
     
            List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title,VersionDataUrl 
                FROM ContentVersion WHERE ContentDocumentId IN : fileIDs];
            Map<ID, String> mapIdTitle = new Map<ID, String>();
            for (ContentVersion docLink : docs) {
                mapIdTitle.put(docLink.ContentDocumentId, docLink.VersionDataUrl);
            }
            return mapIdTitle;
        }
    
    @AuraEnabled(cacheable=true)
    public static String getTowerId_ForUnitBluePrint( String unitId){
        List<Module__c> lstUnit=[Select id,Tower__c,Project__c from module__c where id=: unitId and Record_Type_Name__c='Unit'];
        String towerId;
        for(Module__c unit : lstUnit){
            towerId= unit.Tower__c;
        }
        system.debug(towerId);
        return towerId; 
    }
    
        @AuraEnabled(cacheable=true)
    public static String getTowerId_ForFloorBluePrint( String floorId){
        List<Module__c> lstFloors=[Select id,Tower__c,Floor_Name__c from module__c where id=: floorId and Record_Type_Name__c='Floor'];
        String towerId;
        for(Module__c floor : lstFloors){
            towerId= floor.Tower__c;
        }
        system.debug(towerId);
        return towerId; 
    }
}