// Test Class : TestTaxInvoiceController
public class taxInvoiceController {
    
    public List<Payment__c> pList {get;set;}
    public List<Account> accList {get;set;}
    public List<Payment__c> pListAmount {get;set;}
    //    public List<Product2> prodList {get;set;}
    public Id payId {get;set;}
    public Decimal AmountAV {get;set;}
    public Decimal AmountGST {get;set;}
    public Decimal AmountTDS {get;set;}
    public Decimal TotalAmt {get;set;}
    public String app2Name {get;set;}
    public String app2pan {get;set;}
    public String app3Name {get;set;}
    public String app3pan {get;set;}
    
    public taxInvoiceController(){
        Id payId = ApexPages.currentPage().getParameters().get('id');
        pList = new List<Payment__c>();
        taxMethod(payId);
    } 
    
    
    public void taxMethod(String payId){
        if(payId != Null){
            pList = [SELECT Id, Name,Opportunity__c, Account__c,Customer_Code__c,Opportunity__r.Project__r.Name,Demand_Letter_Date__c,Due_Date__c,
                     Opportunity__r.Tower1__r.Name,Opportunity__r.Product_Saleable__r.Material_Code__c,Document_Number__c,
                     Opportunity__r.Product_Saleable__r.Name,Opportunity__r.Account.Name,Opportunity__r.Account.Customer_Address__c,
                     Opportunity__r.Account.City_O__c,Opportunity__r.Account.Pincode__c,Opportunity__r.Account.State_Province__c,
                     Opportunity__r.Account.Country__c,Opportunity__r.Account.PersonMobilePhone,Opportunity__r.Account.PAN_No__c,
                    Previous_Outstanding__c,Advanced_Received__c
                     FROM Payment__c where Id =: payId AND RecordType.Name = 'Invoice'];
            //    prodList = [Select Name,Material_Code__c from Product2 where Opportunity__c =: pList[0].Opportunity__c];
            System.debug('pList:: '+pList);
            System.debug('pList[0].Account__c :: '+pList[0].Account__c);
            System.debug('Payment Name :: '+pList[0].Name);
            System.debug('Opportunity related to payment :: '+pList[0].Opportunity__c);
            pListAmount = [SELECT Id, Name,Opportunity__c,Assignment__c,Amount__c from Payment__c where Opportunity__c =: pList[0].Opportunity__c and Name =:pList[0].Name];
            System.debug('pListAmount size ::'+ pListAmount.size());
            System.debug('pListAmount :: '+pListAmount);
            
            if(pListAmount.size() != 0){
                for(Payment__c p:pListAmount){
                    if(p.Assignment__c == 'Ageement Value'){
                        AmountAV = p.Amount__c;
                    }
                    else if(p.Assignment__c == 'GST'){
                        AmountGST = p.Amount__c;
                    }
                    else if(p.Assignment__c == 'TDS'){
                        AmountTDS = p.Amount__c;
                    }
                }
                if(AmountAV != Null && AmountGST != Null && AmountTDS != Null){
                    TotalAmt = AmountAV + AmountGST + AmountTDS;  
                }
                
            }
            System.debug('AmountAV :: '+AmountAV);
            System.debug('AmountGST :: '+AmountGST);
            System.debug('AmountTDS :: '+AmountTDS);
            System.debug('TotalAmt :: '+TotalAmt);
            System.debug('pList[0].Account__c :: '+pList[0].Account__c);
            if(pList[0].Account__c != Null){
                accList = [select id,name,PAN_No__c,ParentId from Account where ParentId =:pList[0].Account__c  limit 2];
                System.debug('accList :: '+accList);
                System.debug('accList size :: '+accList.size());
            }
            if(accList.size() == 1){
                app2Name = accList[0].name;
                app2pan = accList[0].PAN_No__c;
            }
            else if(accList.size() == 2){
                app2Name = accList[0].name;
                app2pan = accList[0].PAN_No__c;
                app3Name = accList[1].name;
                app3pan = accList[1].PAN_No__c;
            }
            
        }
        
    }

}