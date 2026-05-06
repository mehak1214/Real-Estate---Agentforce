public with sharing class reimTowerUnitsCount {
    
    @AuraEnabled(cacheable=true)
public static Integer getTowerCount(String ProjectId) {
    String proId= ProjectId;
    List<Module__c> modules = [SELECT Tower_Name__c FROM Module__c WHERE Project__c = :proId];
    
    Set<String> uniqueTowerNames = new Set<String>();
    for (Module__c module : modules) {
        if (module.Tower_Name__c != null) {
            uniqueTowerNames.add(module.Tower_Name__c);
        }
    }
    
    Integer towerCount = uniqueTowerNames.size();
    System.debug('Total Tower Names: ' + towerCount);
    return towerCount;
}


    @AuraEnabled(cacheable=true)
    public static Integer getUnitCount(String ProjectId) {
        String proId = ProjectId;
        AggregateResult[] results = [SELECT COUNT(Unit_Name__c) unitcnt FROM Module__c WHERE Floor__r.Wing__r.Tower__r.Project__c=:proId  GROUP BY Floor__r.Wing__r.Tower__r.Project__c];
        
        if (results.size() > 0) {
            Integer modUnitCount = (Integer)results[0].get('unitcnt');
           
            System.debug('Total Units are: ' + modUnitCount);
            return modUnitCount;
        }
        
        return 0; // Return 0 if no results are found
    }
    @AuraEnabled(cacheable=true)
    public static Integer getSoldUnitCount(String ProjectId) {
        String proId = ProjectId;
        String Status = 'Sold';
        AggregateResult[] results = [SELECT COUNT(Unit_Name__c) unitcnt	 FROM Module__c WHERE Floor__r.Wing__r.Tower__r.Project__c=:proId AND Unit_Status__c=:Status  GROUP BY Floor__r.Wing__r.Tower__r.Project__c];
        
        if (results.size() > 0) {
            Integer modSoldUnitCount = (Integer)results[0].get('unitcnt');
           
            System.debug('Total Sold Units are: ' + modSoldUnitCount);
            return modSoldUnitCount;
        }
        
        return 0; // Return 0 if no results are found
    }
    @AuraEnabled(cacheable=true)
    public static Integer getAvlUnitCount(String ProjectId) {
        String proId = ProjectId;
        String Status = 'Available';
        AggregateResult[] results = [SELECT COUNT(Unit_Name__c) unitcnt	 FROM Module__c WHERE Floor__r.Wing__r.Tower__r.Project__c=:proId AND Unit_Status__c=:Status  GROUP BY Floor__r.Wing__r.Tower__r.Project__c];
        
        if (results.size() > 0) {
            Integer modAvlUnitCount = (Integer)results[0].get('unitcnt');
           
            System.debug('Total Available Units are: ' + modAvlUnitCount);
            return modAvlUnitCount;
        }
        
        return 0; // Return 0 if no results are found
    }
}