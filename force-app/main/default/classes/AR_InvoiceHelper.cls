public class AR_InvoiceHelper {
    public static void fillTriggerAmount(List<AR_Invoice__c> newList) 
    {
        for(AR_Invoice__c inv: newList)
        {
            inv.Trigger_Amount__c = inv.Amount__c;
            if(String.ValueOf(inv.Invoice_Date__c) == '' || String.ValueOf(inv.Invoice_Date__c) == null)
            {
                inv.Invoice_Date__c = System.Today();
            }

        } 
    }
    
    public static void ApplyInvoicesFIFO(List<AR_Invoice__c> newList) 
    {
        List<AR_Receipt__c> genericReceiptList = new List<AR_Receipt__c>();
        List<AR_Receipt__c> receiptOtherInvoices = new List<AR_Receipt__c>();
        List<AR_Receipt__c> receiptsToUpdate = new List<AR_Receipt__c>();
        List<AR_Invoice__c> invoiceInstallmentList = new List<AR_Invoice__c>();
        List<AR_Invoice__c> invoiceOtherList = new List<AR_Invoice__c>();
        List<AR_Invoice__c> invoicesToUpdate = new List<AR_Invoice__c>();
        List<AR_Applied_For__c> appliedForToInsert = new List<AR_Applied_For__c>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> entityIds = new Set<Id>();
        
        for(AR_Invoice__c inv : newList)
        {
            if(inv.Oracle_Migrated__c == true || inv.Omit_fifo__c == true){
                break;
            }
           if(String.isNotEmpty(inv.Opportunity__c)){
            	oppIds.add(inv.Opportunity__c);
            }
            if(String.isNotEmpty(inv.Account__c)){
               accIds.add(inv.Account__c); 
            }
            if(inv.Opportunity__c == null && inv.issued_To__c !=null)
            {
                entityIds.add(inv.issued_To__c);
            }
            invoiceInstallmentList.add(inv);
        }
        List<AR_Receipt__c> installmentReceiptList = new List<AR_Receipt__c>();
        List<AR_Receipt__c> entityReceiptList = new List<AR_Receipt__c>();
        List<AR_Receipt__c> accountReceiptList = new List<AR_Receipt__c>();
        
        if (Schema.sObjectType.AR_Receipt__c.isAccessible())
        {
            installmentReceiptList = [SELECT Id, Opportunity__c,Status__c,Trigger_Amount__c, Amount__c,Unapplied_Amount__c, Payment_Date__c, Charge_Type__c, Charge_Code__c,Reservation_Receipt__c, Financial_Status__c 
                                      FROM AR_Receipt__c 
                                      WHERE Opportunity__c IN:oppIds AND Opportunity__c != null AND Status__c != 'Fully Applied' AND Status__c != 'Cancelled' AND Financial_Status__c != 'Reversed'  
                                      ORDER BY Payment_Date__c ASC];
            if(entityIds.size() > 0)
            {
                 entityReceiptList = [SELECT Id, Opportunity__c,Status__c,Trigger_Amount__c, Amount__c,Unapplied_Amount__c, Payment_Date__c, Charge_Type__c, Charge_Code__c,Reservation_Receipt__c,Legal_Entity__c,Account__c,Financial_Status__c 
                                 FROM AR_Receipt__c 
                                 WHERE Opportunity__c = null AND Account__c = null AND Issued_To__c IN:entityIds AND Status__c != 'Fully Applied' AND Status__c != 'Cancelled' AND Financial_Status__c != 'Reversed' 
                                 ORDER BY Payment_Date__c ASC];
            }
         
            if(accIds.size()>0)
            {
                accountReceiptList = [SELECT Id, Opportunity__c,Status__c,Trigger_Amount__c, Amount__c,Unapplied_Amount__c, Payment_Date__c, Charge_Type__c, Charge_Code__c,Reservation_Receipt__c,Legal_Entity__c,Account__c,Financial_Status__c 
                                  FROM AR_Receipt__c 
                                  WHERE Opportunity__c = null AND Account__c IN:accIds AND Account__c !=null AND Status__c != 'Fully Applied' AND Status__c != 'Cancelled' AND Financial_Status__c != 'Reversed' 
                                  ORDER BY Payment_Date__c ASC];
            }
           
        }
        
        Map<Id,List<AR_Receipt__c>> receiptInsMap = new Map<Id,List<AR_Receipt__c>>();
        for(AR_Receipt__c rec : installmentReceiptList)
        {
            if(!receiptInsMap.containsKey(rec.Opportunity__c))
            {
                receiptInsMap.put(rec.Opportunity__c, new List<AR_Receipt__c>());
                receiptInsMap.get(rec.Opportunity__c).add(rec);
            } else 
            {
                receiptInsMap.get(rec.Opportunity__c).add(rec);
            }
        }
        
        Map<Id,List<AR_Receipt__c>> receiptEntityMap = new Map<Id,List<AR_Receipt__c>>();
        for(AR_Receipt__c rec : entityReceiptList)
        {
            if(!receiptEntityMap.containsKey(rec.Legal_Entity__c))
            {
                receiptEntityMap.put(rec.Legal_Entity__c, new List<AR_Receipt__c>());
                receiptEntityMap.get(rec.Legal_Entity__c).add(rec);
            } else 
            {
                receiptEntityMap.get(rec.Legal_Entity__c).add(rec);
            }
        }
        
        Map<Id,List<AR_Receipt__c>> receiptAccountMap = new Map<Id,List<AR_Receipt__c>>();
        for(AR_Receipt__c rec : accountReceiptList)
        {
            if(!receiptAccountMap.containsKey(rec.Account__c))
            {
                receiptAccountMap.put(rec.Account__c, new List<AR_Receipt__c>());
                receiptAccountMap.get(rec.Account__c).add(rec);
            } else 
            {
                receiptAccountMap.get(rec.Account__c).add(rec);
            }
        }
        
        for(AR_Invoice__c inv : invoiceInstallmentList)
        {
            AR_Invoice__c tmp = new AR_Invoice__c();
            tmp.Id = inv.Id;
            tmp.Trigger_Amount__c = inv.Trigger_Amount__c;
            genericReceiptList = receiptInsMap.get(inv.Opportunity__c);
            if(genericReceiptList == null)
            {
                genericReceiptList = receiptEntityMap.get(inv.issued_To__c);
            }
            if(genericReceiptList == null)
            {
                genericReceiptList = receiptAccountMap.get(inv.Account__c);
            }
            if(genericReceiptList != null)
            {
                Integer c = 0;
                Double currInvoiceAmount = tmp.Trigger_Amount__c;
                for(AR_Receipt__c rec : genericReceiptList)
                {
                    if(rec.Reservation_Receipt__c == true)
                    {
                        if(rec.Charge_Code__c == inv.Charge_Code__c)
                        {
                            AR_Applied_For__c appFor = new AR_Applied_For__c();
                            appFor.Applied_Amount__c = rec.Trigger_Amount__c;
                            appFor.Status__c = 'Applied';
                            appFor.Invoice__c = inv.Id;
                            appFor.Receipt__c = rec.Id;
                            tmp.Status__c = 'Fully Paid'; 
                            rec.Status__c = 'Fully Applied';
                            rec.Trigger_Amount__c = 0;
                            tmp.Trigger_Amount__c = 0;
                            currInvoiceAmount = 0; 
                            if(appFor.Applied_Amount__c > 0)
                            {
                                appliedForToInsert.add(appFor);
                            }
                            if(!receiptsToUpdate.Contains(rec))
                            {
                                receiptsToUpdate.add(rec);
                            }
                            if(!invoicesToUpdate.Contains(tmp))
                            {
                                invoicesToUpdate.add(tmp);
                            }
                        }
                    }else if (rec.Reservation_Receipt__c == false)
                    {
                        if(rec.Trigger_Amount__c == currInvoiceAmount && currInvoiceAmount > 0 && rec.Charge_Type__c == inv.Charge_Type__c)
                        {
                            AR_Applied_For__c appFor = new AR_Applied_For__c();
                            appFor.Applied_Amount__c = rec.Trigger_Amount__c;
                            appFor.Invoice__c = inv.Id;
                            appFor.Receipt__c = rec.Id;
                            appFor.Status__c = 'Applied';
                            if(appFor.Applied_Amount__c > 0)
                            {
                                appliedForToInsert.add(appFor);
                            }
                            tmp.Status__c = 'Fully Paid';
                            rec.Status__c = 'Fully Applied';
                            rec.Trigger_Amount__c = 0;
                            tmp.Trigger_Amount__c = 0;
                            if(!receiptsToUpdate.Contains(rec))
                            {
                                receiptsToUpdate.add(rec);
                            }
                            if(!invoicesToUpdate.Contains(tmp))
                            {
                                invoicesToUpdate.add(tmp);
                            }
                            currInvoiceAmount = 0;
                        }
                        if(rec.Trigger_Amount__c > 0 && rec.Trigger_Amount__c > currInvoiceAmount && currInvoiceAmount > 0 && rec.Charge_Type__c == inv.Charge_Type__c)
                        {
                            AR_Applied_For__c appFor = new AR_Applied_For__c();
                            appFor.Applied_Amount__c = currInvoiceAmount;
                            appFor.Invoice__c = inv.Id;
                            appFor.Receipt__c = rec.Id;
                            appFor.Status__c = 'Applied';
                            tmp.Status__c = 'Fully Paid';
                            rec.Status__c = 'Partially Applied';
                            rec.Trigger_Amount__c -= currInvoiceAmount;
                            currInvoiceAmount = 0;
                            tmp.Trigger_Amount__c -= rec.Trigger_Amount__c;
                            if(!receiptsToUpdate.Contains(rec))
                            {
                                receiptsToUpdate.add(rec);
                            }
                            if(!invoicesToUpdate.Contains(tmp))
                            {
                                invoicesToUpdate.add(tmp);
                            }
                            if(appFor.Applied_Amount__c > 0)
                            {
                                appliedForToInsert.add(appFor);
                            }
                            
                        }
                        
                        if(rec.Trigger_Amount__c > 0 && rec.Trigger_Amount__c < currInvoiceAmount && currInvoiceAmount > 0 && rec.Charge_Type__c == inv.Charge_Type__c)
                        {
                            AR_Applied_For__c appFor = new AR_Applied_For__c();
                            appFor.Applied_Amount__c = rec.Trigger_Amount__c;
                            appFor.Invoice__c = inv.Id;
                            appFor.Receipt__c = rec.Id;
                            appFor.Status__c = 'Applied';
                            tmp.Status__c = 'Partially Paid';
                            rec.Status__c = 'Fully Applied';
                            currInvoiceAmount -= rec.Trigger_Amount__c;
                            tmp.Trigger_Amount__c -= rec.Trigger_Amount__c;
                            rec.Trigger_Amount__c = 0;
                            if(!receiptsToUpdate.Contains(rec))
                            {
                                receiptsToUpdate.add(rec);
                            }
                            if(!invoicesToUpdate.Contains(tmp))
                            {
                                invoicesToUpdate.add(tmp);
                            }
                            if(appFor.Applied_Amount__c > 0)
                            {
                                appliedForToInsert.add(appFor);
                            }
                        }
                        c++;
                    }  
                }
            }else
            {
                tmp.Status__c = 'Pending Payment';
                if(!invoicesToUpdate.Contains(tmp))
                {
                    invoicesToUpdate.add(tmp);
                }
            }
            
            if(genericReceiptList == null)
            {
                tmp.Status__c = 'Pending Payment';
                if(!invoicesToUpdate.Contains(tmp))
                {
                    invoicesToUpdate.add(tmp);
                }   
            }
        }
                
        if(appliedForToInsert.Size() > 0)
        {
            insert appliedForToInsert;
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

}