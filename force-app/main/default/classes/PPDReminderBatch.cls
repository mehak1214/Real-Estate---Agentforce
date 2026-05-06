//Keep Batch Size as1
public class PPDReminderBatch implements Database.Batchable<sObject>{

    public static String emailBodyTemplate = 'Dear {1},\n\n'+
                                             'I hope you\'re well. This is a friendly reminder that the payment of AED {2} for invoice #{3} is due on {4}. Please let us know if you\'ve already made the payment or if you need any assistance.\n\n'+
                                             'Thank you for your attention to this matter!';
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        Date dueDate =  Date.valueOf(Label.PPD_Email_Due_Date);
        String query = 'SELECT Id, Name, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Account.Name, Opportunity__r.Account.PersonEmail, Status__c, Invoice_Due_Date__c,Installment_No__c, Installment_Amount__c FROM Payment_Plan_Detail__c';
        query += ' WHERE Status__c NOT IN (\'Paid\') AND Opportunity__r.AccountId != NULL AND Invoice_Due_Date__c =: dueDate';
        System.debug('>> '+ query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Payment_Plan_Detail__c> scope){
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Payment_Plan_Detail__c objPPD = scope[0];
        if(objPPD.Opportunity__r.Account.PersonEmail != null){
            // Create Email
            String subject = 'Payment reminder for Invoice# ' + objPPD.Installment_No__c;
            String emailBody = emailBodyTemplate.replace('{1}', objPPD.Opportunity__r.Account.Name);
            emailBody = emailBody.replace('{2}', String.valueOf(objPPD.Installment_Amount__c));   
            emailBody = emailBody.replace('{3}', objPPD.Installment_No__c);
            emailBody = emailBody.replace('{4}', String.valueOf(objPPD.Invoice_Due_Date__c));

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses( new List<String>{objPPD.Opportunity__r.Account.PersonEmail} );
            message.setSubject(subject);
            message.setplaintextbody(emailBody);
            emailList.add(message);

            if(!emailList.isEmpty()){
                Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emailList); //Sending email
                for(Messaging.SendEmailResult emailResult : emailResults){
                    if(emailResult.IsSuccess()){
                        Task emailActivityTask = new Task();
                        emailActivityTask.Subject = subject;
                        emailActivityTask.Description = emailBody;
                        emailActivityTask.WhatId = objPPD.Opportunity__r.AccountId;
                        emailActivityTask.Priority = 'Normal';
                        emailActivityTask.Status = 'Closed';
                        emailActivityTask.TaskSubtype = 'Email';
                        emailActivityTask.ActivityDate = Date.today();
                        insert emailActivityTask;       //Creating EMail Activity
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC){}
}