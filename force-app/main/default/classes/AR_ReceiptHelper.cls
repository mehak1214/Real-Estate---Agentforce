public class AR_ReceiptHelper {
    public static void fillTriggerAmount(List<AR_Receipt__c> newList) 
    {
        for(AR_Receipt__c rec: newList)
        {
            rec.Trigger_Amount__c = rec.Amount__c;
            if(String.ValueOf(rec.Receipt_Date__c) == '' || String.ValueOf(rec.Receipt_Date__c) == null)
            {
                rec.Receipt_Date__c = System.Today();   
            }
            //rec.Amount_In_Words__c = AR_NumberToWords.convertNumberToWords(Integer.ValueOf(rec.Amount__c));
            //rec.Amount_In_Words__c = AR_NumberToWords.convertNumberToWords(rec.Amount__c);// Added as part of Bug Fix SAR-492
        }
    }
    
    public static void ApplyReceiptsFIFO(List<AR_Receipt__c> newList) {
        List<AR_Invoice__c> genericInvoiceList = new List<AR_Invoice__c>();
        List<AR_Invoice__c> receiptOtherInvoices = new List<AR_Invoice__c>();
        List<AR_Invoice__c> invoicesToUpdate = new List<AR_Invoice__c>();
        List<AR_Receipt__c> receiptInstallmentList = new List<AR_Receipt__c>();
        List<AR_Receipt__c> receiptOtherList = new List<AR_Receipt__c>();
        List<AR_Receipt__c> receiptsToUpdate = new List<AR_Receipt__c>();
        List<AR_Applied_For__c> appliedForToInsert = new List<AR_Applied_For__c>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> entityIds = new Set<Id>();
        
        for(AR_Receipt__c rec : newList)
        {
            if(rec.Oracle_Migrated__c == true || rec.Omit_fifo__c == true)
            {
                break;
            }
            if(String.isNotEmpty(rec.Opportunity__c)){
           	 	oppIds.add(rec.Opportunity__c);
            }
            if(String.isNotEmpty(rec.Account__c)){
           	 	accIds.add(rec.Account__c);
            }
            if(rec.Opportunity__c == null && rec.Is_Dummy_Receipt__c == false && rec.Issued_To__c != null)
            {
                entityIds.add(rec.Issued_To__c); 
            }
            receiptInstallmentList.add(rec);
        }
        List<AR_Invoice__c> installmentInvoiceList = new List<AR_Invoice__c>();
        List<AR_Invoice__c> entityInvoiceList = new List<AR_Invoice__c>();
        List<AR_Invoice__c> accountInvoiceList = new List<AR_Invoice__c>();
        
        if (Schema.sObjectType.AR_Invoice__c.isAccessible())
        {
            installmentInvoiceList = [SELECT Id, Transaction_Id__c,Opportunity__c,Status__c,Trigger_Amount__c, Amount__c, Invoice_Date__c, Charge_Type__c 
                                      FROM AR_Invoice__c 
                                      WHERE Opportunity__c IN:oppIds AND Opportunity__c != null AND Status__c != 'Fully Paid' AND Status__c != 'Reversed'
                                      ORDER BY Invoice_Date__c ASC];
            
            if(entityIds.size() > 0)
            {
                entityInvoiceList = [SELECT Id, Transaction_Id__c,Opportunity__c,Status__c,Trigger_Amount__c, Amount__c, Invoice_Date__c, Charge_Type__c,Account__c,issued_To__c 
                                     FROM AR_Invoice__c 
                                     WHERE Opportunity__c = null AND Account__c = null AND issued_To__c IN:entityIds AND Status__c != 'Fully Paid' AND Status__c != 'Reversed'
                                     ORDER BY Invoice_Date__c ASC];
                
            }
            
            
            if(accIds.size()>0)
            {
                accountInvoiceList = [SELECT Id,Transaction_Id__c, Opportunity__c,Status__c,Trigger_Amount__c, Amount__c, Invoice_Date__c, Charge_Type__c,Account__c,issued_To__c 
                                      FROM AR_Invoice__c 
                                      WHERE Opportunity__c = null AND Account__c IN:accIds AND Account__c !=null AND Status__c != 'Fully Paid' AND Status__c != 'Reversed'
                                      ORDER BY Invoice_Date__c ASC];
                
            }
            
        }
        
        
        Map<Id,List<AR_Invoice__c>> invInsMap = new Map<Id,List<AR_Invoice__c>>();
        for(AR_Invoice__c inv : installmentInvoiceList)
        {
            if(!invInsMap.containsKey(inv.Opportunity__c))
            {
                invInsMap.put(inv.Opportunity__c, new List<AR_Invoice__c>());
                invInsMap.get(inv.Opportunity__c).add(inv);
            } else 
            {
                invInsMap.get(inv.Opportunity__c).add(inv);
            }
        }
        
        Map<Id,List<AR_Invoice__c>> invEntityMap = new Map<Id,List<AR_Invoice__c>>();
        for(AR_Invoice__c inv : entityInvoiceList)
        {
            if(!invEntityMap.containsKey(inv.issued_To__c))
            {
                invEntityMap.put(inv.issued_To__c, new List<AR_Invoice__c>());
                invEntityMap.get(inv.issued_To__c).add(inv);
            } else 
            {
                invEntityMap.get(inv.issued_To__c).add(inv);
            }
        }
        
        Map<Id,List<AR_Invoice__c>> invAccountMap = new Map<Id,List<AR_Invoice__c>>();
        for(AR_Invoice__c inv : accountInvoiceList)
        {
            if(!invAccountMap.containsKey(inv.Account__c))
            {
                invAccountMap.put(inv.Account__c, new List<AR_Invoice__c>());
                invAccountMap.get(inv.Account__c).add(inv);
            } else 
            {
                invAccountMap.get(inv.Account__c).add(inv);
            }
        }
        
        //Applying Installment Receipt on Insallment Invoices
        for(AR_Receipt__c rec : receiptInstallmentList)
        {
            AR_Receipt__c tmp = new AR_Receipt__c();
            tmp.Id = rec.Id;
            tmp.Trigger_Amount__c = rec.Trigger_Amount__c;
            genericInvoiceList = invInsMap.get(rec.Opportunity__c);
            if(genericInvoiceList == null)
            {
                genericInvoiceList = invEntityMap.get(rec.Issued_To__c);
            }
            if(genericInvoiceList == null)
            {
                genericInvoiceList = invAccountMap.get(rec.Account__c);
            }
            if(genericInvoiceList != null)
            {
                Double currReceiptAmount = rec.Trigger_Amount__c;                
                for(AR_Invoice__c inv : genericInvoiceList)
                {
                    String swithType = 'NormalFiFo';
                    if((rec.Payment_Type__c == 'Real Connect Payments' || rec.Source_System__C == 'Kiosk') &&  rec.Charge_Type__c !='Installments' && rec.Charge_Type__c !='CC Charges'){
                        swithType = 'RealConnectFIFO';
                    }
                    switch on swithType {
                        when 'RealConnectFIFO' {
                            // Adding below Logic as the Trigger
                            if(currReceiptAmount > 0 && rec.External_ID__c  == inv.Transaction_Id__c &&   rec.Charge_Type__c == inv.Charge_Type__c)
                            {
                                AR_Applied_For__c appFor = new AR_Applied_For__c();
                                appFor = createAppliedForRecord(currReceiptAmount,inv.Id,rec.Id,'Applied');
                                if(appFor.Applied_Amount__c > 0)
                                {
                                    appliedForToInsert.add(appFor);
                                }
                                inv.Status__c = 'Fully Paid'; // Invoice Details
                                inv.Trigger_Amount__c = 0;    // Invoice Details
                                tmp.Status__c = 'Fully Applied'; // Receipt Details
                                tmp.Trigger_Amount__c = 0;  // Receipt Details
                                if(!receiptsToUpdate.Contains(tmp))
                                {
                                    receiptsToUpdate.add(tmp);
                                }
                                if(!invoicesToUpdate.Contains(inv))
                                {
                                    invoicesToUpdate.add(inv);
                                }
                                currReceiptAmount = 0;
                            }
                        }
                        when else {
                            if(inv.Trigger_Amount__c == currReceiptAmount && currReceiptAmount > 0 && rec.Charge_Type__c == inv.Charge_Type__c)
                            {
                                AR_Applied_For__c appFor = new AR_Applied_For__c();
                                appFor = createAppliedForRecord(currReceiptAmount,inv.Id,rec.Id,'Applied');
                                if(appFor.Applied_Amount__c > 0)
                                {
                                    appliedForToInsert.add(appFor);
                                }
                                inv.Status__c = 'Fully Paid'; // Invoice Details
                                inv.Trigger_Amount__c = 0;    // Invoice Details
                                tmp.Status__c = 'Fully Applied'; // Receipt Details
                                tmp.Trigger_Amount__c = 0;  // Receipt Details
                                if(!receiptsToUpdate.Contains(tmp))
                                {
                                    receiptsToUpdate.add(tmp);
                                }
                                if(!invoicesToUpdate.Contains(inv))
                                {
                                    invoicesToUpdate.add(inv);
                                }
                                currReceiptAmount = 0;
                            }
                            if(currReceiptAmount > 0 && inv.Trigger_Amount__c < currReceiptAmount && inv.Trigger_Amount__c > 0 && rec.Charge_Type__c == inv.Charge_Type__c)
                            {
                                AR_Applied_For__c appFor = new AR_Applied_For__c();
                                appFor = createAppliedForRecord((Double)inv.Trigger_Amount__c,inv.Id,rec.Id,'Applied');
                                tmp.Trigger_Amount__c -= inv.Trigger_Amount__c; // Receipt Details
                                tmp.Status__c = 'Partially Applied';    // Receipt Details
                                currReceiptAmount -= inv.Trigger_Amount__c; // Invoice Details
                                inv.Trigger_Amount__c = 0;  // Invoice Details
                                inv.Status__c = 'Fully Paid'; // Invoice Details
                                if(!receiptsToUpdate.Contains(tmp))
                                {
                                    receiptsToUpdate.add(tmp);
                                }
                                if(!invoicesToUpdate.Contains(inv))
                                {
                                    invoicesToUpdate.add(inv);
                                }
                                if(appFor.Applied_Amount__c > 0)
                                {
                                    appliedForToInsert.add(appFor);
                                }
                            }
                            if(currReceiptAmount > 0 && inv.Trigger_Amount__c > currReceiptAmount && rec.Charge_Type__c == inv.Charge_Type__c)
                            {
                                AR_Applied_For__c appFor = new AR_Applied_For__c();
                                appFor = createAppliedForRecord(currReceiptAmount,inv.Id,rec.Id,'Applied');
                                inv.Trigger_Amount__c -= currReceiptAmount;  // Invoice Details
                                inv.Status__c = 'Partially Paid';            // Invoice Details
                                currReceiptAmount = 0;  // Receipt Details
                                tmp.Trigger_Amount__c -= inv.Trigger_Amount__c;  // Receipt Details
                                tmp.Status__c = 'Fully Applied'; // Receipt Details
                                if(!receiptsToUpdate.Contains(tmp))
                                {
                                    receiptsToUpdate.add(tmp);
                                }
                                if(!invoicesToUpdate.Contains(inv))
                                {
                                    invoicesToUpdate.add(inv);
                                }
                                if(appFor.Applied_Amount__c > 0)
                                {
                                    appliedForToInsert.add(appFor);
                                }
                            }   
                        }
                    }
                }
            }else
            {
                tmp.Status__c = 'Not applied/Hold';
                if(!receiptsToUpdate.Contains(tmp))
                {
                    receiptsToUpdate.add(tmp);
                }
            }
            
            if(genericInvoiceList == null)
            {
                tmp.Status__c = 'Not applied/Hold';
                if(!receiptsToUpdate.Contains(tmp))
                {
                    receiptsToUpdate.add(tmp);
                }
            }
        }
        
        if(!Test.isRunningTest()){
            if(appliedForToInsert.Size() > 0)
            {
                insert appliedForToInsert;
            }
        }
        if(invoicesToUpdate.Size() > 0)
        {
            update invoicesToUpdate;
        }
        
        if(receiptsToUpdate.Size() > 0)
        {
            update receiptsToUpdate;
        }
        
        
    }
    
    public static AR_Applied_For__c createAppliedForRecord(Double amountToBeApplied,Id invId,Id recId,String appliedForStatus){
        AR_Applied_For__c appFor = new AR_Applied_For__c();
        appFor.Applied_Amount__c = amountToBeApplied;
        appFor.Invoice__c = invId;
        appFor.Receipt__c = recId;
        appFor.Status__c = appliedForStatus;
        return appFor;
    }

}