/**********************************************************************************************
* @Author: Prajwal Tijare
* @Created Date: 12 Nov 2025
* @Description: Helper class for Payment_Plan_Detail__c trigger. 
*               This class is responsible for generating AR_Invoice__c records 
*               automatically whenever a Payment Plan Detail record’s status is updated to 'Progressed'.
**************************************************************************************************/
/*************************************************************************************************
@Version History
* Version      Date             Name         	Description
* 1.0          12NOV2025        Prajwal     Initial draft - Invoice generation on status change to 'Progressed'
**************************************************************************************************/
public class PaymentPlanDetailHelper {
    
    public static void generateInvoices(List<Payment_Plan_Detail__c> newList, Map<Id, Payment_Plan_Detail__c> oldMap) {
        List<AR_Invoice__c> newInvoiceList = new List<AR_Invoice__c>();
        
        for (Payment_Plan_Detail__c ppd : newList) {
            Payment_Plan_Detail__c oldRec = oldMap.get(ppd.Id);
            if (oldRec != null && ppd.Status__c != oldRec.Status__c && ppd.Status__c == 'Progressed') {
                
                AR_Invoice__c newInvoice = new AR_Invoice__c();
                newInvoice.Name = ppd.Installment_No__c;
                //newInvoice.Account__c = ppd.Account__c;
                newInvoice.Amount__c = ppd.Amount__c;
                newInvoice.Charge_Code__c = ppd.Charge_Code__c;
                newInvoice.Inventory__c = ppd.Inventory__c;
                newInvoice.Opportunity__c = ppd.Opportunity__c;
                newInvoice.Payment_Plan_Detail__c = ppd.Id;
                newInvoice.Status__c = 'Pending Payment';
                newInvoice.Charge_Type__c = 'Installments';
                
                if (ppd.Instalment_Type__c == 'Fixed Date') {
                    newInvoice.Invoice_Date__c = ppd.Cheque_Date__c;
                } else {
                    newInvoice.Invoice_Date__c = Date.today();
                }
                
                newInvoice.Installment_Date__c = ppd.Cheque_Date__c;
                newInvoiceList.add(newInvoice);
            }
        }
        
        if (!newInvoiceList.isEmpty()) {
            try {
                insert newInvoiceList;
            } catch (Exception e) {
                System.debug('Invoice insertion failed: ' + e.getMessage());
            }
        }
    }
}