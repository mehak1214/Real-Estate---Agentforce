global class PaymentPlanReminderEmailBatch  implements Database.Batchable<SObject> {
    
   public static String emailBodyTemplate = 
    '<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">' +
    '<p>Dear {1},</p>' +
    '<p>' +
    'I hope you\'re well. This is a friendly reminder that the payment of ' +
    '<strong>AED {2}</strong> for invoice <strong>#{3}</strong> is due on ' +
    '<strong>{4}</strong>.' +
    '</p>' +
    '<p>' +
    'Please let us know if you\'ve already made the payment or if you need any assistance.' +
    '</p>' +
    '<p>Thank you for your attention to this matter!</p>';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> statusNotConsiderd = new Set<String>{'Paid'};
            return Database.getQueryLocator([
                SELECT Id, Name, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Account.Name, Opportunity__r.Primary_Contact__c, 
                Opportunity__r.Account.PersonEmail, Status__c, Invoice_Due_Date__c,Installment_No__c, Installment_Amount__c
                FROM Payment_Plan_Detail__c
                WHERE  Status__c NOT IN :statusNotConsiderd AND Opportunity__r.AccountId != NULL AND
                Invoice_Due_Date__c = :Date.today()
            ]);
    }
    
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Payment_Plan_Detail__c rec : (List<Payment_Plan_Detail__c>)scope) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setSubject('Payment Plan Reminder - Invoice Due Today '+ rec.Installment_No__c);
            
            String emailBody = emailBodyTemplate.replace('{1}', rec.Opportunity__r.Account.Name);
            emailBody = emailBody.replace('{2}', String.valueOf(rec.Installment_Amount__c));   
            emailBody = emailBody.replace('{3}', rec.Installment_No__c);
            emailBody = emailBody.replace('{4}', String.valueOf(rec.Invoice_Due_Date__c));
            
            email.setHTMLbody(emailBody);
            email.setWhatId(rec.Opportunity__r.Account.Id);
            email.setTargetObjectId(rec.Opportunity__r.Primary_Contact__c);
            email.setSaveAsActivity(true);
            email.setToAddresses(new String[] { rec.Opportunity__r.Account.PersonEmail });
            
            emails.add(email);
            
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Reminder Emails Sent');
    }
}