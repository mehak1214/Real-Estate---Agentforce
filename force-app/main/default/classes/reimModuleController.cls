public class reimModuleController {
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getTowers(String ProjectId) {
        ID proId=ProjectId;
        Id towerRecordTypeId = Schema.SObjectType.Module__c.getRecordTypeInfosByName().get('Tower').getRecordTypeId();
        system.debug('towerRecordTypeId'+towerRecordTypeId);        
        List<Module__c> modTowerRec = new List<Module__c>(); 
        
                modTowerRec = [SELECT Id, Name, Tower_Name__c, Project__c, Project__r.Name, UniqueCode__c FROM Module__c WHERE Project__c = :proId AND RecordTypeId = :towerRecordTypeId ORDER BY Tower_Name__c ASC];
                System.debug('Module Towers=====>' + modTowerRec.size());
                return modTowerRec;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getWings(String ProjectId,String towerName) {
       
        String proId = ProjectId;
        String twrName= towerName;
        List<Module__c> modWingRec = new List<Module__c>(); 
        modWingRec = [Select Id,Wing_Name__c,Tower__r.Tower_Name__c,UniqueCode__c,Tower__r.UniqueCode__c,Tower__r.Project__c FROM Module__c WHERE Tower__r.Project__c = :proId AND Tower__r.Tower_Name__c =:twrName ];
        System.debug('getWings=====>' + modWingRec);
        return modWingRec;
 
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Module__c> getFloors(String towerName) {  
        String twrName = towerName;
        List<Module__c> modFloorRec = new List<Module__c>(); 
        modFloorRec = [Select Id,Floor_Name__c,UniqueCode__c,Wing__r.UniqueCode__c,Wing__r.Tower__r.Project__c FROM Module__c WHERE  Wing__r.Tower__r.Tower_Name__c =:twrName ];
        System.debug('getFloors=====>' + modFloorRec);
        return modFloorRec;        
    }
    
     @AuraEnabled(cacheable=true)
    public static List<Module__c> getUnits(String ProjectId, String floorUniqCode) {
       
        String proId = ProjectId;
        
        String flooruniquecode = floorUniqCode;
        List<Module__c> modUnitRec = new List<Module__c>(); 
        modUnitRec = [Select Id,Unit_Name__c    ,UniqueCode__c,Floor__r.UniqueCode__c,Floor__r.Wing__r.Tower__r.Project__c FROM Module__c WHERE Floor__r.Wing__r.Tower__r.Project__c = :proId AND Floor__r.UniqueCode__c =:floorUniqCode ];
        System.debug('getUnits=====>' + modUnitRec);
        return modUnitRec;
 
        
    }
      
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUnitsByFloor(String wingtowerId) {
        String wtowerId = wingtowerId;
        
        Map<String, Object> floorUnitMap = new Map<String, Object>();
        
        List<Module__c> modUnitRec = [
            SELECT Id, Unit_Name__c, Unit_Status__c, Floor__c, Floor__r.Floor_Name__c
            FROM Module__c
            WHERE Floor__r.Wing__r.Tower__c = :wtowerId
        ORDER BY Floor__r.Floor_Name__c DESC,Unit_Name__c ASC
        ];
        
        for (Module__c module : modUnitRec) {
            String floorId = module.Floor__c;
            String floorName = String.valueof(module.Floor__r.Floor_Name__c);
            String unitName = module.Unit_Name__c;
            String unitStatus = module.Unit_Status__c;
            
            if (!floorUnitMap.containsKey(floorName)) {
                floorUnitMap.put(floorName, new Map<String, String>());
            }
            
            ((Map<String, String>)floorUnitMap.get(floorName)).put(unitName, unitStatus);
        }
        
        System.debug('Floor Unit Map: ' + floorUnitMap);
        return floorUnitMap;
    }
    
@AuraEnabled(cacheable=true)
    public static List<Module__c> openFloors(String towerId, Integer FloorName) {
       String twrId = towerId;
       Integer flrName = FloorName;
        List<Module__c> modFloorRec = new List<Module__c>(); 
        modFloorRec = [Select Id,Unit_Name__c,Floor__r.Floor_Name__c,Floor__r.Floor_Image__c,Unit_Status__c  from Module__c where Floor__r.Wing__r.Tower__c=: towerId AND Floor__r.Floor_Name__c=: flrName ORDER BY Unit_Name__c ASC];
        System.debug('openFloors=====>' + modFloorRec);
        return modFloorRec;
 
        
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Module__c> openUnit(String towerId, String unitName) {
       String twrId = towerId;
       String uName = unitName;
        List<Module__c> modFloorRec = new List<Module__c>(); 
        modFloorRec = [Select Id,Unit_Name__c,Floor__r.Floor_Name__c,Unit_Size__c,Unit_Type__c,Unit_Plan_Image__c,Unit_Description__c, Unit_Bedroom_Count__c,Unit_Bathroom_Count__c,Total_Price__c, Price_Per_Sqft__c,Floor__r.Wing__r.Tower__r.Tower_Name__c,Unit_Status__c,Floor__r.Wing__r.Wing_Name__c,Carpet_Area__c, Balcony__c 
                        from Module__c where Floor__r.Wing__r.Tower__c=: towerId AND Unit_Name__c=: uName ORDER BY Unit_Name__c ASC];
        System.debug('openUnit=====>' + modFloorRec);
        return modFloorRec;
        
    }

    /* Dev : Sushant Salunkhe 
    Code to get the list of available unit on the Floor Plan page for every Tower
    */
    @AuraEnabled(cacheable=true)
    public static Integer getAvailableUnitsPerTower(String towerId) {
        String twrId = towerId;
         List<Module__c> modFloorRec = new List<Module__c>(); 
         modFloorRec = [Select Id,Floor__r.Wing__r.Tower__r.Tower_Name__c,Unit_Status__c,Floor__r.Wing__r.Wing_Name__c from Module__c 
                        where Floor__r.Wing__r.Tower__c=: towerId and  Unit_Status__c='Available' ORDER BY Unit_Name__c ASC];
         System.debug('openUnit=====>' + modFloorRec);
         return modFloorRec.size();
         
     }
   
}