public with sharing class AgentOnboardingController {

@AuraEnabled
public static Id createBrokerRegistrationCase(
String firstName,
String lastName,
String email,
String phone,
String nationalId
){

Id recordTypeId = Schema.SObjectType.Case
.getRecordTypeInfosByName()
.get('Broker Registration')
.getRecordTypeId();

Case c = new Case();

c.RecordTypeId = recordTypeId;
c.First_Name__c = firstName;
c.Last_Name__c = lastName;
c.Email__c = email;
c.Phone__c = phone;
c.National_ID__c = nationalId;
c.Approval_Status__c = 'Draft';

insert c;

return c.Id;

}


@AuraEnabled
public static void updateBrokerRegistrationCase(

Id caseId,
String firstName,
String lastName,
String email,
String phone,
String nationalId
){

Case c = [SELECT Id FROM Case WHERE Id=:caseId];

c.First_Name__c = firstName;
c.Last_Name__c = lastName;
c.Email__c = email;
c.Phone__c = phone;
c.National_ID__c = nationalId;
c.Approval_Status__c = 'Submitted';

update c;

}


/* FILE UPLOAD */

@AuraEnabled
public static String uploadFile(

Id parentId,
String fileName,
String base64Data,
String contentType,
String fileDescription
){

Blob body = EncodingUtil.base64Decode(base64Data);

ContentVersion cv = new ContentVersion();

cv.Title = fileName;
cv.PathOnClient = fileName;
cv.VersionData = body;

insert cv;

cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id];

ContentDocumentLink link = new ContentDocumentLink();

link.LinkedEntityId = parentId;
link.ContentDocumentId = cv.ContentDocumentId;
link.ShareType = 'V';
link.Visibility = 'AllUsers';

insert link;

return 'SUCCESS';

}

@AuraEnabled(cacheable=true)
public static List<Case> getLastCases(){

    return [
        SELECT Id, CaseNumber, First_Name__c, Last_Name__c, Email__c,
               CreatedDate, Approval_Status__c
        FROM Case
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
}
@AuraEnabled
public static List<Map<String,Object>> getLastApplications(){

    List<Case> caseList = [
        SELECT Id,
               First_Name__c,
               Last_Name__c,
               Email__c,
               Approval_Status__c
        FROM Case
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];

    List<Map<String,Object>> result = new List<Map<String,Object>>();

    for(Case c : caseList){

        String stage;
        String status;

        if(c.Approval_Status__c == 'Draft'){
            stage = 'Process Incomplete';
            status = 'Inactive';
        }
        else if(c.Approval_Status__c == 'Submitted'){
            stage = 'Under Approval';
            status = 'Inactive';
        }
        else if(c.Approval_Status__c == 'Approved'){
            stage = 'User Onboarded';
            status = 'Active';
        }
        else{
            stage = c.Approval_Status__c;
            status = 'Inactive';
        }

        result.add(new Map<String,Object>{
            'Id' => c.Id,
            'Name' => c.First_Name__c + ' ' + c.Last_Name__c,
            'Email' => c.Email__c,
            'Stage' => stage,
            'Status' => status
        });

    }

    return result;
}

}