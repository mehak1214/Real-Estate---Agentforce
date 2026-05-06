public class GenerateReceiptController {
    public List<Payment__c> pList {get;set;}
    
    public GenerateReceiptController(){
        Id payId = ApexPages.currentPage().getParameters().get('id');
        pList = new List<Payment__c>();
        
        pList = [SELECT Id, Name,Opportunity__c, Account__c,Customer_Code__c,Opportunity__r.Project__r.Name,Demand_Letter_Date__c,Due_Date__c,
                 Opportunity__r.Tower1__r.Name,Opportunity__r.Product_Saleable__r.Material_Code__c,Document_Number__c,
                 Opportunity__r.Product_Saleable__r.Name,Opportunity__r.Account.Name,Opportunity__r.Account.Customer_Address__c,
                 Opportunity__r.Account.City_O__c,Opportunity__r.Account.Pincode__c,Opportunity__r.Account.State_Province__c,
                 Opportunity__r.Account.Country__c,Opportunity__r.Account.PersonMobilePhone,Opportunity__r.Account.PAN_No__c,
                Previous_Outstanding__c,Advanced_Received__c,Amount__c,
                 Assignment__c,Posting_Date__c,Status__c,Bank_Name__c,Clearing_Document_Number__c,Cheque_No__c,Customer_Receipt_Number__c,
                 Cheque_Clearing_Date__c,Document_Clearing_Date__c,Tax_Amount__c,Tax_Code__c,Sp_GL_Indicator__c,Sp_GL_Indicator_Code__c,
                 Reversal_Doc__c,Reversal_Reason__c,Reversal_Reason_Code__c
                 FROM Payment__c where Id =: payId AND RecordType.Name = 'Invoice'];
        //    prodList = [Select Name,Material_Code__c from Product2 where Opportunity__c =: pList[0].Opportunity__c];
        System.debug('pList:: '+pList);
    }
}