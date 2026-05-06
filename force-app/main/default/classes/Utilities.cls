public with sharing class Utilities {
    
   //Added by Maaz for converting numeric values into words
   static final Integer DIGITS_PER_SET = 3;
   static final String ZERO = 'Zero';
   private static Map<Integer,String> tens = new Map<Integer,String> {
       20 => 'Twenty',
       30 => 'Thirty',
       40 => 'Forty',
       50 => 'Fifty',
       60 => 'Sixty',
       70 => 'Seventy',
       80 => 'Eighty',
       90 => 'Ninety'
   };
   private static Map<Integer,String> smallNumbers = new Map<Integer,String> {
       0 => 'Zero',
       1 => 'One',
       2 => 'Two',
       3 => 'Three',
       4 => 'Four',
       5 => 'Five',
       6 => 'Six',
       7 => 'Seven',
       8 => 'Eight',
       9 => 'Nine',
       10 => 'Ten',
       11 => 'Eleven',
       12 => 'Twelve',
       13 => 'Thirteen',
       14 => 'Fourteen',
       15 => 'Fifteen',
       16 => 'Sixteen',
       17 => 'Seventeen',
       18 => 'Eighteen',
       19 => 'Nineteen'
   };
   private static Map<Integer,String> modifiers = new Map<Integer,String> {
       1 => 'Thousand ',
       2 => 'Million ',
       3 => 'Billion '
   };    

   public static String NumberToTextconvert(Integer value) 
   {
    // zero is a special case
    if (value == 0)
        return ZERO;

    // text representation of the number to convert. e.g. 'one hundred'
    String numberText = '';

    // If value is negative prepend the text with 'negative'
    // and then process as a positive value
    if (value < 0) {
        numberText = 'negative ';
        value *= -1;
    }

    // string representation of the number to convert. e.g. '100'
    String numberString = String.valueOf(value);

    // split the number into sets (hundreds, thousands, millions, billions)
    // and convert each as a three digit number.
    while(numberString.length() > 0){
        // Figure out how many digits are in this set
        Integer digits = Math.mod(numberString.length(), DIGITS_PER_SET) == 0 ?
                         DIGITS_PER_SET :
                         Math.mod(numberString.length(), DIGITS_PER_SET);

        // Create a string to represent this set.
        String thisSet = numberString.substring(0, digits);

        // Convert the set into an integer and generate the text for this set.
        Integer valueToConvert = Integer.valueOf(thisSet);

        // Remove the first set from numberString now that it has been converted.
        numberString = numberString.substring(digits, numberString.length());

        if (valueToConvert > 0) {                
            String setText = NumberToTextgenerateText(valueToConvert);

            // Calculate the modifierIndex to determine what set this is
            // e.g. thousands, millions, billions.
            Integer modifierKey = numberString.length() / DIGITS_PER_SET;

            // Create the modifier string
            String modifier = modifierKey > 0 ? ' ' + modifiers.get(modifierKey) : '';

            // Build the text
            numberText += setText + modifier;
        }
    }    
    return numberText.trim();
}

private static String NumberToTextgenerateText(Integer value) {
    if (value < 100)
        return generateTextForTwoDigits(value);

    String numberText = '';

    // Calculate the number of hundreds
    Integer hundreds = value / 100;
    if (hundreds > 0)
        numberText = generateTextForTwoDigits(hundreds) + ' Hundred';

    // Calculate the leftover value
    Integer leftOver = Math.mod(value, 100);
    if (leftOver > 0)
        numberText += ' ' + generateTextForTwoDigits(leftOver);
    return numberText;
}

private static String generateTextForTwoDigits(Integer value) {
    if (value < 20) {
        return smallNumbers.get(value);
    }

    // Round the value down to the nearest 10 and get the text representation
    Integer tensKey = (value/10) * 10;
    String numberText = tens.get(tensKey);

    // Calculate the leftover value
    Integer leftOver = value - tensKey;

    if (leftOver > 0) {
        // Add a hypen for values between 21 - 99.
        // https://www.grammarly.com/blog/hyphen-in-compound-numbers/
        if (tensKey >= 20 && tensKey <= 90 && leftOver > 0) {
            numberText += '-';
        }
        numberText += generateTextForTwoDigits(leftOver);
    }
    return numberText;
}
  //Added by Maaz till here for number conversion to text values  


    public static Map<String,String> constantsMap ;
    public static String objType = '';
    public static User userDetail ;
    
    
    
    
    
    //Get System Messages
    
    @auraEnabled(cacheable=true)
    public static map<string,string> getPicklistValues(String objName,String fieldName){
        Map<string,string> pickValMap = new  Map<string,string>();     
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        System.debug('fields'+fieldResult);
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){           
            pickValMap.put(pickListVal.getLabel(),pickListVal.getValue());
        }
        return pickValMap;
        
    }  
    
    public static String getOrgWideEmailAddressId(){
        try{
            
            OrgWideEmailAddress orgWideEmailAddress = [Select id,Address From OrgWideEmailAddress LIMIT 1];
            
            return orgWideEmailAddress.Id;
        }
        catch(exception ex){
            system.debug(ex.getMessage());
            return null;
        }
    }

    public static Messaging.SingleEmailMessage getEmailInstance( string targetObject, string templateID,string whatId , List<String> toRecipients,List<String> bccRecipients,List<String> ccRecipients,String emailSubject,String body,string htmlBody,List<Messaging.EmailFileAttachment> fileAttachments,string orgWideEmailAddressID) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(false);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if(targetObject!=null && targetObject!=''){
            mail.setTargetObjectId(targetObject);
        }
        if(whatId!=null && whatId!=''){
            mail.setWhatId(whatId);
        }
        if(templateID!=null && templateID!=''){
            mail.setTemplateID(templateID);
        }
        if(emailSubject!=null && emailSubject!=''){
            mail.setSubject(emailSubject);
        }
        if(toRecipients!=null && !toRecipients.isEmpty() ){
            mail.setToAddresses(toRecipients);
        }
        if(bccRecipients != null && !bccRecipients.isEmpty() ){
            mail.setccAddresses(bccRecipients);
        }
        if(ccRecipients != null && !ccRecipients.isEmpty()){
            mail.setbccAddresses(ccRecipients);
        }
        if (body!=null && body!='') {
            mail.setPlainTextBody(body);
        } 
        if (htmlBody!=null && htmlBody!='') {
            mail.setHtmlBody(htmlBody);
        }
        if(OrgWideEmailAddressID != null && OrgWideEmailAddressID!=''){
            mail.setOrgWideEmailAddressId(OrgWideEmailAddressID);
        }
        // Specify FileAttachments
        if(fileAttachments != null && !fileAttachments.isEmpty()) {
            mail.setFileAttachments(fileAttachments);
        }
        return mail;
    }   
    
    /**
* SendEmailWithTemplateID 
*
* This method will trigger send email logic
* 
* @usage all apex based emails
*
* @param    mails     list<Messaging.SingleEmailMessage> to be sent
*
* @return none
*/
    public static list<Messaging.SendEmailResult> sendEmail(list<Messaging.SingleEmailMessage> mails) {
        return Messaging.sendEmail(mails); 
    }
   
    /*
    Get Current user profileName 
    */

    @AuraEnabled(cacheable=false)
    public static string getCurrentUserProfileName(){
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        system.debug('ProfileName' + PROFILE[0].Name);
        Return PROFILE[0].Name;

    }
    
    
    /*
* Get Record Type Id by Object
*/
    public static Id getRecordTypeId(String objectName, String recordTypeName){
        Map<String,Schema.SObjectType> schemaDescribe = Schema.getGlobalDescribe();  
        Schema.DescribeSObjectResult describeResult = schemaDescribe.get(objectName).getDescribe();
        return(describeResult.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
    }
   
    /*
* Get Domain URL for VF page
*/
    @AuraEnabled(cacheable=false)
    public static String getVFDomainURL(){
        String currentDomainURL = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm();
//        currentDomainURL = baseURL.split('.my.')[0] + '--c.' + 'visualforce.com'; 
        currentDomainURL = baseURL.split('.sandbox.')[0] + '--c.' + 'sandbox.vf.force.com'; 
        return currentDomainURL ;     
    }
    
    public class MyPickListInfo {
        public String validFor;
    }



    public static string amountInWords(decimal amount, string currencyUnit, String currencySubUnit){
        String amountInWords = '';
        if(amount !=null){
            Decimal totalAmount = amount.setScale(2) ;
            String totalAmountString = String.valueOf(totalAmount);
            String beforeDecimal='';
            String afterDecimal='';
            
            if(totalAmountString.contains('.')){
                beforeDecimal = totalAmountString.substringBefore('.');
                beforeDecimal = NumberToTextconvert(Integer.valueOf(beforeDecimal));
                
                afterDecimal = totalAmountString.substringAfter('.');
                afterDecimal = NumberToTextconvert(Integer.valueOf(afterDecimal));
                
            }else{
                beforeDecimal = NumberToTextconvert(Integer.valueOf(totalAmount));
            }
            
            if(String.isNotBlank(beforeDecimal)){
                amountInWords =  beforeDecimal + ' '+currencyUnit+' ';
            }
            if(String.isNotBlank(afterDecimal) && afterDecimal !='Zero'){
                amountInWords = amountInWords + 'and ' +afterDecimal + ' '+currencySubUnit+' ';
            }
            amountInWords = amountInWords +'Only.' ;
        }
        return amountInWords;
    }
    
    public static Messaging.EmailFileAttachment setEmailFileAtt(ContentVersion cvObj) {
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
        Blob fileData = cvObj.VersionData;
        emlAtt.setFilename(cvObj.Title);
        emlAtt.setBody(fileData);
        return emlAtt;
    }
    
     public static List<String> getUsersInPublicGroup(String GroupName) {
        List<User> groupUsers = new List<User>();
         List<String>getUserEmails = New List<String>();
        Group publicGroup = [SELECT Id,Name,DeveloperName FROM Group where DeveloperName=:GroupName];
         System.debug('publicGroup'+publicGroup);
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :publicGroup.Id];
        
        Set<Id> userIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            userIds.add(member.UserOrGroupId);
        }
        
        
        groupUsers = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];
         for(User u:groupUsers){
             getUserEmails.add(u.Email);
         }
        
        return getUserEmails;
    }      
    
    public static Sobject getDataWithAllFields(Id recordId){

        String sObjectName = recordId.getSObjectType().getDescribe().getName();

        Set<String> FieldList = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().keySet();

        String fields = string.join(new list<string>(FieldList),',');      

        String query = 'SELECT ' + fields +' From '+sObjectName+' WHERE Id = :recordId';       

        return Database.Query(query);

        

    }
    
     private static final List<String> N2W_ONES = new List<String>{
        '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
        'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
        'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    };
    
    private static final List<String> N2W_TENS = new List<String>{
        '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    };
    
    private static final List<String> N2W_THOUSANDS = new List<String>{
        '', 'Thousand', 'Million', 'Billion'
    };
    
    /** Convert an integer (Long) to words using Western scale (up to Billions). */
    public static String n2wInteger(Long num) {
        if (num == null) return '';
        if (num == 0)     return 'Zero';
    
        String result = '';
        Integer idx = 0;
        Long n = Math.abs(num);
    
        while (n > 0) {
            Integer chunk = Integer.valueOf(Math.mod(n, 1000));
            if (chunk != 0) {
                String part = n2wChunk(chunk);
                String suffix = N2W_THOUSANDS[idx];
                result = (part + (String.isNotBlank(suffix) ? ' ' + suffix : '') + ' ' + result).trim();
            }
            n = n / 1000;
            idx++;
        }
    
        if (num < 0) result = 'Negative ' + result;
        // Normalize whitespace and hyphens are produced only within chunk words.
        return result.replaceAll('\\s+', ' ').trim();
    }
    
    /** Convert a 0..999 chunk. */
    private static String n2wChunk(Integer chunkValue) {
        Integer c = chunkValue;
        String out = '';
    
        if (c >= 100) {
            Integer hundreds = c / 100;
            out += N2W_ONES[hundreds] + ' Hundred';
            c = Math.mod(c, 100);
            if (c > 0) out += ' ';
        }
    
        if (c >= 20) {
            Integer tensDigit = c / 10;
            Integer unitsDigit = Math.mod(c, 10);
            out += N2W_TENS[tensDigit];
            if (unitsDigit != 0) out += '-' + N2W_ONES[unitsDigit];
        } else if (c > 0) {
            out += N2W_ONES[c];
        }
    
        return out;
    }
    
    /**
     * Convert a money amount into words like:
     * "One Hundred Twenty-Three Dirhams and Five Fils Only"
     *
     * @param amount    monetary amount (will be rounded to 2 decimals for subunit)
     * @param unit      major unit label (e.g., 'Dirhams', 'Rupees', 'Dollars')
     * @param subUnit   minor unit label (e.g., 'Fils', 'Paise', 'Cents')
     */
    public static String amountToWords(Decimal amount, String unit, String subUnit) {
        if (amount == null) return '';
    
        // Whole part
        Long intPart = amount.longValue();
    
        // Fractional part as 0..99 after rounding to 2 decimals
        Decimal rounded = amount.setScale(2);
        Decimal frac = (rounded - rounded.setScale(0)) * 100;
        Integer decPart = frac.abs().setScale(0).intValue(); // always positive 0..99
    
        String words = n2wInteger(intPart) + ' ' + unit;
        if (decPart > 0) {
            words += ' and ' + n2wInteger(Integer.valueOf(decPart)) + ' ' + subUnit;
        }
        return words + ' Only';
    }
    public String formatDayMonth(Date dt) {
        DateTime dtTime = DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
        return dtTime.format('dd MMMM');
    }
     public class WebServiceException extends Exception {
        public Integer statusCode {get;set;}
    }

    public class UnitsAlreadyBookedException extends Exception {
        public List<Unit__c> units {get;set;}
        public Set<Id> unitRemoved {get;set;}
    }

    public class UnitsTimerExpiredException extends Exception {
        public List<Unit__c> units {get;set;}
    }

    public class DataNotCompleteException extends Exception{
        public List<String> messages {get;set;}
    }
    

    public class PaymentPlanException extends Exception{}
    public class BudgetUnAvailableException extends Exception{}    
    public class UpdatingAccountsWithDifferentTypesException extends Exception{}
    public class IncorrectFilterException extends Exception{}
    public class MultipleEOIException extends Exception {}

    

}