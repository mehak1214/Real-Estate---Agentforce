public class BlockPageController {
    public Product2 prod{get;set;}
    public Product2 prod1{get;set;}
    public blocking__c block{get;set;}
    public string callfunc{get;set;}
    public  id prodId{get;set;}
    public string OptyID{get;set;}
    public String message{get;set;}
    public string blockMessage{get;set;}
    public boolean displayPopup {get; set;}     
    
    
    public PageReference BlockPageControllerAction(){
        blockMessage = ApexPages.currentPage().getParameters().get('block');
        if(blockMessage != NULL){
            callfunc='<script> showToast(\'' +blockMessage+ '\'); </script>';
        }
        
        prod = new Product2();
        block = new blocking__c();
        string pid = ApexPages.currentPage().getParameters().get('pid');
        OptyID = ApexPages.currentPage().getParameters().get('OptyID');
        system.debug('OptyID'+ApexPages.currentPage().getParameters().get('OptyID'));
        Opportunity Opp = new Opportunity();
        if(OptyID != null && !string.isBlank(OptyID) && OptyID!='null'){
           Opp = [Select ID, Name from Opportunity where ID =: OptyID];
            system.debug('OptyID'+Opp);
            if(Opp != NULL){
                block.Opportunity__c = Opp.Id;
            }
        }
        system.debug('pid'+pid);
        try{
            if(pid != NULL && pid != ''){
                prod1 = [select Id,Name,Project__c,Tower__c, Unit_Status__c, Opportunity__c from Product2 where Id =: pid];
                system.debug('prod1'+prod1);
                if(prod1!=NULL){
                }
            }
        }catch(exception e){
            
        }
        if(blockMessage != NULL){
            return new PageReference('/apex/S_InventoryMatrixview');
        }
        return NULL;
    }
    public void closePopup() {        
        displayPopup = false;    
    } 
    
    Public string selectedname{get;set;}
    Public List<Selectoption> getselectedaccnamefields(){
        
        Schema.DescribeFieldResult fieldResult = Product2.Unit_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        List<Selectoption> lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('', '- None -'));
        for( Schema.PicklistEntry f : ple)
        {
            lstnamesel.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return lstnamesel; 
    }
    
    public PageReference save(){
        displayPopUp = true;
        try{
            block.Unit__c = prod1.Id;
            Insert block;
            if(block.Id != NULL){ 
                if(block.Action__c == 'Block'){
                    Update new Product2(Id=prod1.Id,Unit_Status__c='Hold');
                    system.debug('inside Hold');
                    displayPopup = true;    
                    Message = 'SUCCESS : Blocking of unit '+prod1.Name+ ' against Opportunity Successfully done';
                }else{
                    Message = 'Unit '+prod1.Name+' status set Unblock';
                }
            }else{
                Message= 'Fail : Blocking of unit '+prod1.Name+ ' against Opportunity fail';
            }
        }
        catch(exception e){
            Message = 'Fail : System failure while blocking unit --> Error : '+e;    
        }
        return NULL;
    }
    
    public PageReference cancel(){
        return new PageReference('/apex/S_InventoryMatrixview?projectsent='+prod.Project__c+'&towersent='+prod.Tower__c);
    }
    
}