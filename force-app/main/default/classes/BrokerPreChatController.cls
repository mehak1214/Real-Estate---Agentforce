public with sharing class BrokerPreChatController {

   @InvocableMethod
public static List<Output> execute(List<Input> inputs) {
    String contactId = inputs[0].input_brokerContactId;
    
    // Fallback: if contactId is null/empty, get from logged-in user
    if (String.isBlank(contactId)) {
        User u = [SELECT ContactId FROM User 
                  WHERE Id = :UserInfo.getUserId() 
                  LIMIT 1];
        contactId = u.ContactId;
    }
    
    // rest of your logic using contactId
}
}