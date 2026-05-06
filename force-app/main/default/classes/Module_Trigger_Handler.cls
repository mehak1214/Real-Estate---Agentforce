public class Module_Trigger_Handler {
    public static void update_unitsLinkedWithFloor(List<Module__c> lstUnits){
        String fp_value='';
        Set<ID> ids=new Set<ID>();
        for(Module__c mod:lstUnits){
            ids.add(mod.Floor__c);
        }
        
        List<Module__c> lstFloors=[Select id, FloorPlan__c from Module__c where Record_Type_Name__c='Floor' AND id=:ids];
        
        for(Module__c floors : lstFloors){
            fp_value=fp_value+floors.FloorPlan__c;
            for(Module__c units : lstUnits){
                if(floors.Id==units.Floor__c){
                    String name = units.Unit_Name__c;
					String result = name.substringAfter('Unit ');
                	fp_value=fp_value+result+', ';  
                }  
                floors.FloorPlan__c=fp_value.removeEnd(',');
            } 
            Database.update(lstFloors);
        }
        
    }
}