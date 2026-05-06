public without sharing class leadConvertAutoCtrl {
    @InvocableMethod
    public static void assignLeads(List<Id> LeadIds){
		leadConvertAutoCtrl.assignPropertyDetails();        
        LeadStatus cLeadStatus=[Select Id,MasterLabel from LeadStatus where isConverted=true limit 1];
        List<Database.LeadConvert> massLeadConvert=new List<Database.LeadConvert>();
        for(Id currentLead:LeadIds){
            Database.LeadConvert LeadConvert=new Database.LeadConvert();
            LeadConvert.setLeadId(currentLead);
            LeadConvert.setConvertedStatus(cLeadStatus.MasterLabel);
            LeadConvert.setDoNotCreateOpportunity(false);
            massLeadConvert.add(LeadConvert);
        }
        
        if(!massLeadConvert.isEmpty()){
           List<Database.LeadConvertResult> lcr=Database.convertLead(massLeadConvert);
            system.debug('lcr:: '+lcr);
            Set<ID> ids=new Set<ID>();
            for(Id ld:LeadIds){
                ids.add(ld);
            }
            ID accID=[select ConvertedAccountId from lead where id=:ids Limit 1].ConvertedAccountId;
            ID oppId=[select ConvertedOpportunityId  from lead where id=:ids Limit 1].ConvertedOpportunityId;
            List<Opportunity> lstOpps=[select id, name, StageName, Project__c, Unit__c, Tower__c, Flat_Unit_Cost__c,Stamp_Duty__c,Society_Charges__c,Registration_Charges__c,Goods_and_Service_Tax_GST__c from Opportunity where id=:oppId];
            for(Opportunity opp : lstOpps){
                opp.StageName='Proposal/Price Quote';
            }
            update lstOpps;
            system.debug('opps updated');
            
            Integer quoteCount=[Select count() from quote where OpportunityId=:oppId];
            Quote quo=new Quote();
            if(quoteCount==0){
            	for(Opportunity opp : lstOpps){
            		quo.Name=opp.Name+' Quote';
                	quo.OpportunityId=oppId;
                	quo.Project__c=opp.Project__c;
                   
            	}
                insert quo;
            }       
        }
    }
 	
    public static void assignPropertyDetails(){
        
}
}