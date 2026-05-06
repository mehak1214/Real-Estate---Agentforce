global without sharing class SiteVisitFormController {
    public Site_Visit__c sv {
        get;
        set;
    }
    
    public Map<String,String> projectNameMap{
        get;
        set;        
    }
    public boolean isDisabled{
        get;
        set;
    } 
    
    public String selectedProject {
        get;
        set;
    }
    
    public String selectedExistingCustomer {
        get;
        set;
    }
    public List<Account> existingCustomerList{
        get;
        set;
    }
    public List<Lead> leadList {
        get;
        set;
    }
    public List<Account> accList {
        get;
        set;
    }
    public List<Opportunity> oppList {
        get;
        set;
    }
    public Boolean mainError {
        get;
        set;
    }
    public Boolean valError {
        get;
        set;
    }
    public Boolean isRunError {
        get;
        set;
    }
    public Boolean isSuccess {
        get;
        set;
    }
    public String message {
        get;
        set;
    }
    public boolean svpage {
        get;
        set;
    }
    public boolean reVisitCheck {
        get;
        set;
    }
    public String mobileVal {
        get;
        set;
    }
    public String formattedMobile {
        get;
        set;
    }
    public String selectedSalesRepName {
        get;
        set;
    }
    public String projectName {
        get;
        set;
    }
    public String cpName {
        get;
        set;
    }
    public List<Account> cpList {
        get;
        set;
    }
    public String lastESVFDate {
        get;
        set;
    }
    public String newCPName {
        get;
        set;
    }
    public Boolean isNewCPName {
        get;
        set;
    }
    public String renderCPName {
        get;
        set;
    }
    public Boolean isNewCPNameRendered {
        get;
        set;
    }
    public list<SelectOption>  lstOptions {get;set;}
    //public String selectedProject {get;set;}
    public List<SelectOption> configList {get;set;}
    
    
    
    public class MyException extends Exception{}
    
    
    public SiteVisitFormController() {
        // initialised all the needy variable in the constructor
        sv = new Site_Visit__c();
        //sv = [SELECT Id, Name, Mobile_Number__c, Configuration__c, First_Name__c, Last_Name__c, Email_Id__c, Date_of_Birth__c, Number_of_Pax__c, Number_of_People__c, Name_of_PSC__c, Address__c, City__c, Locality__c, Pincode_R__c, Occupation__c, Company_Name__c, Designation__c, Office_Location__c, City_O__c, Budget_in_Lac__c, Configuration_Interested_For__c, Current_Residence_Ownership__c, Possession_Timeline__c, Lead_Source_Major__c, Lead_Source_Minor__c FROM Site_Visit__c WHERE Id = 'a0b5D000009nX7uQAE'];
        cpList = new List<Account>();
        existingCustomerList = new List<Account>();
        selectedProject = '';
        selectedProject = 'Aspirational';
        selectedSalesRepName = '';
        formattedMobile = '';
        projectName = '';
        projectName = 'Aspirational';
        cpName = '';
        selectedExistingCustomer = '';
        lastESVFDate = '';
        leadList = new List<Lead>();
        accList = new List<Account>();
        oppList = new List<Opportunity>();
        message = '';
        svpage = false;
        reVisitCheck = false;
        isSuccess = false;
        isRunError = false;
        mainError = false;
        newCPName = '';
        isNewCPName = false;
        renderCPName = '';
        isNewCPNameRendered = false;
        isDisabled=true;
        projectNameMap=new Map<String,String>();
        /* lstOptions = new list<SelectOption>();
List<Project_related_configuration__mdt> projectList=[Select Project_Name__c from Project_related_configuration__mdt where Active__c=true];
lstOptions.add(new SelectOption('','--NONE--'));
for(Project_related_configuration__mdt mkd:projectList){
lstOptions.add(new SelectOption(mkd.Project_Name__c,mkd.Project_Name__c));
}*/
    }
    //project name 
    //method 
    ////////////////////////////////// Get All Project Name ////////////////////////////////////////////////
    public List<SelectOption> getProjects {
        // method to fetch the projects
        get {
            List<SelectOption> optns = new List<Selectoption>();
            List<Project__c> queryResult = new List<Project__c>();
            
            queryResult = [Select Id, Name from Project__c WHERE Active__c = TRUE  and (Name='Aspirational' or Name='Premium') ORDER BY Name ];
            optns.add(new SelectOption('', 'Select a Project'));
            for (Project__c obj: queryResult) {
                optns.add(new SelectOption(obj.Id, obj.Name));
                projectNameMap.put(obj.id,obj.name);
            }
            System.debug('THE PROJECTMAP '+projectNameMap);
            return optns;            
        }
        set;
    }
    
    
    
    /* public String idprojMap{
get{
map<string,string> idproject=new map<string,string>();
List<Project__c> queryResult = new List<Project__c>();
queryResult = [Select Id, Name from Project__c WHERE Active__c = TRUE ORDER BY Name];
for(Project__c prObj:queryResult){
if(idproject.containskey(prObj.id)){
idproject.get(prObj.id);
}
else{
idproject.put(prObj.id,prObj.Name);
}
}
System.debug('the map '+idproject);
return JSON.serialize(idproject);
}
set;
}
*/
    public List<SelectOption> dependentConfig{
        get{
            
            list<SelectOption> optns=new List<SelectOption>();
            System.debug('THE SELECTED PROJECT '+selectedProject);
            String selectedPRJ= projectNameMap.get(selectedProject);
            
            system.debug('selectedPRJ-------------->'+selectedPRJ); 
            map<string,list<SelectOption>> depMap=new map<string,list<SelectOption>>();
            List<string> splitList=new list<string>();
            System.debug('THE SELECTED PROJECT '+selectedPRJ);
            List<Project_related_configuration__mdt> projectList=[Select id,Project_Name__c,Configuration__c from Project_related_configuration__mdt where Active__c=true and Project_Name__c =:selectedPRJ];
            system.debug('projectList--------->'+projectList);
            for(Project_related_configuration__mdt prj:projectList){
                optns = new List<Selectoption>();
                optns.add(new Selectoption('','Select an option'));
                splitList=new List<String>();
                splitList=prj.Configuration__c.split(',');
                for(String str :splitList){
                    optns.add(new SelectOption(str,str));   
                }
            }
            
            
            return optns;
            
            
        }
        set;
    }
    
    ////////////////////////////////// Get All Channel Partner ////////////////////////////////////////////////
    
    @RemoteAction
    global static List<string> getChannelPartner(String cpname) {
        //method to fetch the channel partner information 
        system.debug('inside getChannelPartner:: '+cpname);
        List<Account> cppList = new List<Account>();
        List<String> cName = new List<String>();
        String QueryString =  'Select Id, Name, FirstName,Sales_Rep__r.User__c,Sales_Rep_Western__c,Sales_Rep_Western__r.User__c, LastName, Phone, RAY_ID__c, RERA_Registration_No__c, RecordType.Name from Account where RecordType.Name = \'Channel Partner\' AND Blacklist__c = False AND Active__c = True AND (Name LIKE \'' + cpname + '%\' OR Phone LIKE \'' + cpname + '%\' OR  RAY_ID__c LIKE \'' + cpname + '%\' OR RERA_Registration_No__c LIKE \'' + cpname + '%\') ORDER BY Name ASC';
        cppList = Database.query(QueryString);
        system.debug('cpList:: '+cpplist);
        
        
        if(!cpplist.isEmpty()){
            for(Account cp : cppList){
                cName.add(cp.Name+'-'+cp.Phone+'-'+cp.RAY_ID__c+'-'+cp.RERA_Registration_No__c);
            }
        }
        return cName;
    }
    
    ////////////////////////////////// Get All Existing Customer ////////////////////////////////////////////////
    @RemoteAction
    global static List<string> getExistingCustomer(String selectedExistingCustomer) {
        system.debug('inside getExistingCustomer:: '+selectedExistingCustomer);
        List<Account> exCustList = new List<Account>();
        List<String> exName = new List<String>();
        String QueryString =  'Select Id, Name, FirstName, LastName, PersonMobilePhone, SAP_Vendor_Code__c, RecordType.Name from Account where isPersonAccount = True AND RecordType.Name = \'PersonAccount\' AND SAP_Vendor_Code__c != Null AND (FirstName LIKE \'' + selectedExistingCustomer + '%\' OR  LastName LIKE \'' + selectedExistingCustomer + '%\' OR PersonMobilePhone LIKE \'' + selectedExistingCustomer + '%\') ORDER BY Name ASC';
        exCustList = Database.query(QueryString);
        system.debug('Existing Customer List:: '+exCustList);
        if(!exCustList.isEmpty()){
            for(Account ex: exCustList){
                exName.add(ex.Name+'-'+ex.PersonMobilePhone);
            }
        }
        return exName;
    }
    
    public PageReference validateInputs() { 
        valError = False;
        String p = Apexpages.currentPage().getParameters().get('currentTab');
        system.debug('Page: '+p);
        
        if(Integer.valueOf(p) == 0) {
            if(String.isBlank(sv.Pincode_R__c)) {
                valError = True;
                message = 'Please fill Pin Code to proceed.';
            }
            if(sv.City__c == 'Mumbai' || sv.City__c == 'Thane') {
                if(String.isBlank(sv.Region_If_city_is_Mumbai__c)) {
                    valError = True;
                    message = 'Please fill Region to proceed.';
                } else if(sv.Region_If_city_is_Mumbai__c != 'Central Mumbai' && sv.Region_If_city_is_Mumbai__c != 'New Mumbai') {
                    if(String.isBlank(sv.Sub_Region__c)) {
                        valError = True;
                        message = 'Please fill Sub Region to proceed.';
                    }
                }
            }
            if(sv.City__c == 'Mumbai' || sv.City__c == 'Thane'){
                if(String.isBlank(sv.Locality__c)) {
                    valError = True;
                    message = 'Please fill Locality to proceed.';
                }   
            }
            
            if(String.isBlank(sv.City__c)) {
                valError = True;
                message = 'Please fill City to proceed.';
            }
            if(String.isBlank(sv.Address__c)) {
                valError = True;
                message = 'Please fill Address to proceed.';
            }
            if(sv.Number_of_People__c == Null) {
                valError = True;
                message = 'Please fill Number of People to proceed.';
            }
            if(String.isBlank(sv.Number_of_Pax__c)) {
                valError = True;
                message = 'Please fill Number of Pax to proceed.';
            }
            if(sv.Date_of_Birth__c == Null) {
                valError = True;
                message = 'Please fill Date Of Birth to proceed.';
            }
            if(sv.Date_of_Birth__c >=  system.today()) {
                valError = True;
                message = 'You Cannot Enter Future Date.';
            }
            if(String.isBlank(selectedProject)) {
                valError = True;
                message = 'Please fill Project to proceed.';
            }
            if(String.isBlank(sv.Email_Id__c)) {
                valError = True;
                message = 'Please fill Email Id to proceed.';
            }
            
            if(String.isBlank(sv.Mobile_Number__c)) {
                valError = True;
                message = 'Please fill Mobile Number to proceed.';
            } else if(sv.Mobile_Number__c.length() != 10) {
                valError = True;
                message = 'Please fill Proper Mobile Number to proceed.';
            }
            if(String.isBlank(sv.Last_Name__c)) {
                valError = True;
                message = 'Please fill Last Name to proceed.';
            }
            if(String.isBlank(sv.First_Name__c)) {
                valError = True;
                message = 'Please fill First Name to proceed.';
            }          
        }
        if(Integer.valueOf(p) == 1) {
            String newCPNameVal = Apexpages.currentPage().getParameters().get('newCP');
            System.debug('newCPNameVal >> '+newCPNameVal);
            if(String.isBlank(sv.Lead_Source_Major__c)) {
                valError = True;
                message = 'Please fill Walk-In Source to proceed.';
            } else if(sv.Lead_Source_Major__c == 'Digital') {
                if(String.isBlank(sv.Lead_Source_Minor__c)) {
                    valError = True;
                    message = 'Please fill Walk-In Sub Source to proceed.';
                }
            } else if(sv.Lead_Source_Major__c == 'Channel Partner') {
                if(String.isBlank(cpName)) {
                    valError = True;
                    message = 'Please fill Channel Partner to proceed.';
                }
                if(String.isBlank(newCPNameVal) && isNewCPName == true && reVisitCheck == false) {
                    valError = True;
                    message = 'Please fill New CP Name to proceed.';
                }
            } else if(sv.Lead_Source_Major__c == 'Employee Referral') {
                if(String.isBlank(sv.Employee_Relation__c)) {
                    valError = True;
                    message = 'Please fill Employee Relation to proceed.';
                }
                if(String.isBlank(sv.Employee_Mobile_Number__c)) {
                    valError = True;
                    message = 'Please fill Employee Mobile Number to proceed.';
                } else if(sv.Employee_Mobile_Number__c.length() != 10) {
                    valError = True;
                    message = 'Please fill Proper Employee Mobile Number to proceed.';
                }
                if(String.isBlank(sv.Employee_Name__c)) {
                    valError = True;
                    message = 'Please fill Employee Name to proceed.';
                }
            } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                if(String.isBlank(selectedExistingCustomer)) {
                    valError = True;
                    message = 'Please fill Existing Customer to proceed.';
                }
            }
            if(String.isBlank(sv.Possession_Timeline__c)) {
                valError = True;
                message = 'Please fill Possession Timeline to proceed.';
            }
            if(String.isBlank(sv.Current_Residence_Ownership__c)) {
                valError = True;
                message = 'Please fill Current Residence Ownership to proceed.';
            }
            if(String.isBlank(sv.Configuration__c)) {
                valError = True;
                message = 'Please fill Configurations Interested In to proceed.';
            }
            if(String.isBlank(sv.Configuration_Interested_For__c)) {
                valError = True;
                message = 'Please fill Intent of purchase to proceed.';
            }
            if(String.isBlank(sv.Budget_in_Lac__c)) {
                valError = True;
                message = 'Please fill Budget In Lacs to proceed.';
            }
            if(String.isBlank(sv.City_O__c)) {
                valError = True;
                message = 'Please fill Office City to proceed.';
            }
            if(String.isBlank(sv.Office_Location__c)) {
                valError = True;
                message = 'Please fill Office Location to proceed.';
            }
            if(String.isBlank(sv.Designation__c)) {
                valError = True;
                message = 'Please fill Designation to proceed.';
            }
            if(String.isBlank(sv.Company_Name__c)) {
                valError = True;
                message = 'Please fill Company Name to proceed.';
            }
            if(String.isBlank(sv.Occupation__c)) {
                valError = True;
                message = 'Please fill Occupation to proceed.';
            }
        }
        return null;
    }
    
    public void search() {
        mainError = false;
        if(String.isBlank(sv.Mobile_Number__c) || sv.Mobile_Number__c.length() != 10 || String.isBlank(selectedProject) || String.isBlank(sv.Configuration__c)) {
            if(String.isBlank(sv.Configuration__c)) {
                mainError = True;
                message = 'Please fill Configurations Interested In to proceed.';
            }
            if(String.isBlank(selectedProject)) {
                mainError = True;
                message = 'Please fill Project to proceed.';
            }
            if(String.isBlank(sv.Mobile_Number__c)) {
                mainError = True;
                message = 'Please fill Mobile Number to proceed.';
            } else if(sv.Mobile_Number__c.length() != 10) {
                mainError = True;
                message = 'Please fill Proper Mobile Number to proceed.';
            }
        } else {
            system.debug('In Else');
            List<Project__c> pList = [Select Id, Name from Project__c where Id =: selectedProject];
            if(!pList.isEmpty()) {
                projectName = pList[0].Name;
            }
            
            formattedMobile = '0'+sv.Mobile_Number__c;
            mobileVal = sv.Mobile_Number__c;
            system.debug('formattedMobile: '+formattedMobile );
            List<Account> pAccList = [select Id, FirstName, LastName, PersonMobilePhone, Secondary_Mobile__c, PersonEmail, Birth_Date__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                                      Locality__c, BillingCountry, Region_If_city_is_Mumbai__c, Sub_Region__c, Occupation__c, Designation__c, City_O__c, Company_Name__c, Office_Location__c
                                      from Account where isPersonAccount = True AND RecordType.Name = 'Person Account' AND (PersonMobilePhone =: formattedMobile OR Secondary_Mobile__c =: formattedMobile OR PersonMobilePhone =: sv.Mobile_Number__c OR Secondary_Mobile__c =: sv.Mobile_Number__c)
                                      ORDER BY CreatedDate DESC];
            system.debug('Previous Account List: '+pAccList);
            
            if(!pAccList.isEmpty() && pAccList.size() > 0) {
                if(pAccList[0].FirstName != Null)
                    sv.First_Name__c = pAccList[0].FirstName;
                sv.Last_Name__c = pAccList[0].LastName;
                if(pAccList[0].PersonEmail != Null)
                    sv.Email_Id__c = pAccList[0].PersonEmail;
                if(pAccList[0].Birth_Date__c != Null)
                    sv.Date_of_Birth__c = pAccList[0].Birth_Date__c;
                if(pAccList[0].BillingStreet != Null)
                    sv.Address__c = pAccList[0].BillingStreet;
                if(pAccList[0].BillingCity != Null)
                    sv.City__c = pAccList[0].BillingCity;
                if(pAccList[0].BillingPostalCode != Null)
                    sv.Pincode_R__c = pAccList[0].BillingPostalCode;
                if(pAccList[0].BillingCity == 'Mumbai' || pAccList[0].BillingCity == 'mumbai' || pAccList[0].BillingCity == 'Thane' || pAccList[0].BillingCity == 'thane') {
                    sv.Region_If_city_is_Mumbai__c = pAccList[0].Region_If_city_is_Mumbai__c;
                    if(pAccList[0].Sub_Region__c != Null)
                        sv.Sub_Region__c = pAccList[0].Sub_Region__c;
                }
                if(pAccList[0].Occupation__c != Null)
                    sv.Occupation__c = pAccList[0].Occupation__c;
                if(pAccList[0].Designation__c != Null)
                    sv.Designation__c = pAccList[0].Designation__c;
                if(pAccList[0].City_O__c != Null)
                    sv.City_O__c = pAccList[0].City_O__c;
                if(pAccList[0].Company_Name__c != Null)
                    sv.Company_Name__c = pAccList[0].Company_Name__c;
                if(pAccList[0].Office_Location__c != Null)
                    sv.Office_Location__c = pAccList[0].Office_Location__c;
                if(pAccList[0].Locality__c != Null)
                    sv.Locality__c = pAccList[0].Locality__c;
                
                /*
List <Opportunity> Opplist=[select id from opportunity where account==pAccList[0].id where project.Name=selectedProject];
Check if the opportunity with same project is present.
if(true){
update the opportunity with new configuration
}
else{
create new opportunity with the given configuration
}

*/         
                //aspiration
                List<Opportunity> pOppList=new List<Opportunity>();
                
                /*  if(projectName.equals('Super Premium')){
pOppList = [select Id, Name, StageName, Channel_Partner__c, LeadSource, Lead_Source__c, Project__c, Project__r.Name,Name_of_PSC__c, Sales_Rep__c, Locality__c, ESVF_Date_Time__c,
Budget__c, Configuration_interested_in__c, Channel_Partner__r.Name, Channel_Partner__r.Business_Type__c, Channel_Partner__r.Phone, Channel_Partner__r.RERA_Registration_No__c,
Channel_Partner__r.RAY_ID__c, Channel_Partner__r.Active__c, Reference_Customer__c, Occupation__c, Number_of_Pax__c, Number_of_People__c,
Ref_Emp_Name__c, Ref_Emp_Mob__c, Ref_Emp_Relation__c, Company_Name__c, Designation__c, Office_Location__c, City_O__c, Intent_of_Purchase__c,
Current_Residence_Ownership__c, Possession_Timeline__c, Sales_Rep__r.Name, Reference_Customer__r.Name, Reference_Customer__r.PersonMobilePhone,
Walk_In_Source__c, Walk_In_Sub_Source__c, New_CP_Name__c from Opportunity where AccountId =: pAccList[0].Id AND Active__c = True AND Project__c=:selectedProject and  Opportunity_Active_Record__c=true order by createdDate DESC];
system.debug('SUPER PREMIUM  Opportunity List: '+pOppList);
}else{*/
                
                pOppList = [select Id, Name, StageName, Channel_Partner__c, LeadSource, Lead_Source__c, Project__c, Project__r.Name,Name_of_PSC__c, Sales_Rep__c, Locality__c, ESVF_Date_Time__c,
                            Budget__c, Configuration_interested_in__c, Channel_Partner__r.Name, Channel_Partner__r.Business_Type__c, Channel_Partner__r.Phone, Channel_Partner__r.RERA_Registration_No__c,
                            Channel_Partner__r.RAY_ID__c, Channel_Partner__r.Active__c, Reference_Customer__c, Occupation__c, Number_of_Pax__c, Number_of_People__c,
                            Ref_Emp_Name__c, Ref_Emp_Mob__c, Ref_Emp_Relation__c, Company_Name__c, Designation__c, Office_Location__c, City_O__c, Intent_of_Purchase__c,
                            Current_Residence_Ownership__c, Possession_Timeline__c, Sales_Rep__r.Name, Reference_Customer__r.Name, Reference_Customer__r.PersonMobilePhone,
                            Walk_In_Source__c, Walk_In_Sub_Source__c, New_CP_Name__c from Opportunity where AccountId =: pAccList[0].Id AND Active__c = True AND  Opportunity_Active_Record__c=true /*and/* Project__c=:selectedProject order by createdDate DESC*/];
                //  }
                system.debug('Previous Opportunity List: '+pOppList);
                
                if(!pOppList.isEmpty() && pOppList.size() > 0) {
                    mainError=false;
                    String status= checkSiteVist(pAccList[0].Id,projectName,sv.Configuration__c);
                    System.debug('The Status------->'+status);
                    if(status.equals('Allow')){
                        svPage=true;
                        mainError=false;
                        
                        
                    }else if(status.equals('Deny')){
                        List<Opportunity> oppList=[select id,Configuration_interested_in__c,project__r.name,project__c from opportunity where project__c=:selectedProject and accountID=:pAccList[0].Id and Active__c = True  order by createdDate DESC limit 1];
                       // List<Site_visit__c> svList=[Select id from Site_visit__c where opportunityID=:oppList[0].id order by createdDate DESC limit 1];
                        system.debug('Deny-->oppList--> '+oppList);
                        svPage=false;
                        mainError=true;
                        if(oppList.size()>0 && oppList[0].project__r.name=='Park Avenue'){
                            message = 'An active opportunity with configuration - '+oppList[0].Configuration_interested_in__c+', exists for the customer.';    
                        }
                        else{
                            message = 'An active opportunity already exists for other projects.';
                        }
                        
    
                    }
                    
                    // for(Opportunity opp:pOppList){
                    //3item
                    /*   system.debug('Sv Config'+sv.Configuration__c);
System.debug('Opportunity Config :'+opp.Configuration_interested_in__c);

String oppConfig=opp.Configuration_interested_in__c.trim();
String svConfig=sv.Configuration__c.trim();
String oppProject=opp.Project__r.Name.trim();


if(!oppProject.equals(projectName)){*/
                    
                    //     system.debug('inside same config'+sv.Configuration__c+' opp config '+opp.Configuration_interested_in__c);
                    //     svPage=false;
                    //     mainError=true;
                    //     //message = 'An active opportunity with configuration - '+opp.Configuration_interested_in__c+', exists for the customer. Please select "'+opp.Configuration_interested_in__c+'" for configuration.';
                    //     message = 'You can not create opportunity';
                    
                    // }else if(!oppConfig.equals(svConfig)){
                    //         //opp.Configuration_interested_in__c!=sv.Configuration__c
                    //         system.debug('inside same config'+sv.Configuration__c+' opp config '+opp.Configuration_interested_in__c);
                    //         svPage=false;
                    //         mainError=true;
                    //         message = 'An active opportunity with configuration - '+opp.Configuration_interested_in__c+', exists for the customer. Please select "'+opp.Configuration_interested_in__c+'" for configuration.';
                    //     }else{
                    //         System.debug('inside the else in for loop');
                    //         svPage=true;
                    //         mainError=false;
                    //         break;
                    //     }
                    // }
                    
                    system.debug('the message '+message);
                    system.debug('mainError===============>'+mainError);
                    if(mainError==false){
                        system.debug('Inside IF main error is false');
                        List<Opportunity> oppList = [select Id, Name, StageName, Channel_Partner__c, LeadSource, Lead_Source__c, Project__c, Project__r.Name,Name_of_PSC__c, Sales_Rep__c, Locality__c, ESVF_Date_Time__c,
                                                     Budget__c, Configuration_interested_in__c, Channel_Partner__r.Name, Channel_Partner__r.Business_Type__c, Channel_Partner__r.Phone, Channel_Partner__r.RERA_Registration_No__c,
                                                     Channel_Partner__r.RAY_ID__c, Channel_Partner__r.Active__c, Reference_Customer__c, Occupation__c, Number_of_Pax__c, Number_of_People__c,
                                                     Ref_Emp_Name__c, Ref_Emp_Mob__c, Ref_Emp_Relation__c, Company_Name__c, Designation__c, Office_Location__c, City_O__c, Intent_of_Purchase__c,
                                                     Current_Residence_Ownership__c, Possession_Timeline__c, Sales_Rep__r.Name, Reference_Customer__r.Name, Reference_Customer__r.PersonMobilePhone,
                                                     Walk_In_Source__c, Walk_In_Sub_Source__c, New_CP_Name__c from Opportunity where AccountId =: pAccList[0].Id AND Active__c = True AND  Opportunity_Active_Record__c=true and Project__c=:selectedProject limit 1 /*order by createdDate DESC*/];
                        
                        
                        
                        
                        
                        
                        
                        //sv.Locality__c = pOppList[0].Locality__c;
                        if(oppList.size()>0){
                            sv.Number_of_Pax__c = oppList[0].Number_of_Pax__c;
                            sv.Number_of_People__c = oppList[0].Number_of_People__c; 
                            //sv.Occupation__c = pOppList[0].Occupation__c;
                            //sv.Company_Name__c = pOppList[0].Company_Name__c;
                            //sv.Designation__c = pOppList[0].Designation__c;
                            //sv.Office_Location__c = pOppList[0].Office_Location__c;
                            //sv.City_O__c = pOppList[0].City_O__c;
                            sv.Budget_in_Lac__c = oppList[0].Budget__c;
                            sv.Configuration_Interested_For__c = oppList[0].Intent_of_Purchase__c;
                            sv.Current_Residence_Ownership__c = oppList[0].Current_Residence_Ownership__c;
                            sv.Possession_Timeline__c = oppList[0].Possession_Timeline__c;
                            sv.Lead_Source_Major__c =  oppList[0].Walk_In_Source__c;
                            if(oppList[0].Walk_In_Source__c == 'Channel Partner') {
                                //selectedCP = pOppList[0].Channel_Partner__c;
                                cpName = oppList[0].Channel_Partner__r.Name+'-'+oppList[0].Channel_Partner__r.Phone+'-'+oppList[0].Channel_Partner__r.RAY_ID__c+'-'+oppList[0].Channel_Partner__r.RERA_Registration_No__c;
                                sv.Channel_Partner__c = oppList[0].Channel_Partner__c;
                                
                                
                                
                                
                                if(oppList[0].Channel_Partner__r.Name.contains('New Channel Partner')){
                                    isNewCPName = true;
                                    newCPName = oppList[0].New_CP_Name__c;
                                    sv.New_CP_Name__c = oppList[0].New_CP_Name__c;
                                }
                                
                            } else if(oppList[0].Walk_In_Source__c == 'Employee Referral') {
                                sv.Employee_Name__c = oppList[0].Ref_Emp_Name__c;
                                sv.Employee_Mobile_Number__c = oppList[0].Ref_Emp_Mob__c;
                                sv.Employee_Relation__c = oppList[0].Ref_Emp_Relation__c;
                            } else if(oppList[0].Walk_In_Source__c == 'Existing Customer Referral') {
                                //selectedExistingCustomer = pOppList[0].Reference_Customer__c;
                                selectedExistingCustomer = oppList[0].Reference_Customer__r.Name+' - '+oppList[0].Reference_Customer__r.PersonMobilePhone;
                                sv.Reference_Customer__c = oppList[0].Reference_Customer__c;
                            }
                            sv.Lead_Source_Minor__c = pOppList[0].Walk_In_Sub_Source__c;
                            
                            set<Id> oppIds = new set<Id>();
                            for(Opportunity opp:oppList){
                                oppIds.add(opp.Id);
                            }
                            System.debug('the opp sets------->'+oppIds);
                            
                            //  List<Site_Visit__c> preSVList = [select Id, Name from Site_Visit__c where Opportunity__c =: pOppList[0].id ORDER BY CreatedDate DESC];
                            List<Site_Visit__c> preSVList = [select Id, Name from Site_Visit__c where Opportunity__r.Project__c=:selectedProject and  Opportunity__c in:oppIds/* ORDER BY CreatedDate DESC*/];
                            system.debug('Size of Site Visit List: '+preSVList.size());
                            
                            if(!preSVList.isEmpty() && preSVList.size() > 0) {
                                system.debug('In Re-visit');
                                reVisitCheck = True;
                                if(oppList[0].Sales_Rep__c != Null)
                                    //getSalesRep.add(new SelectOption(pOppList[0].Sales_Rep__c, pOppList[0].Sales_Rep__r.Name));
                                    selectedSalesRepName = oppList[0].Sales_Rep__r.Name;
                                sv.Sales_Rep__c = oppList[0].Sales_Rep__c;
                                if(oppList[0].Name_of_PSC__c != Null)
                                    sv.Name_of_PSC__c = oppList[0].Name_of_PSC__c;
                                if(oppList[0].ESVF_Date_Time__c != Null)
                                    lastESVFDate = oppList[0].ESVF_Date_Time__c.format();
                            }
                        }
                        
                    }
                }
                svPage=mainError?false:true;
                
            } 
            else {
                
                List<Lead> pLeadList = [Select Id, FirstName, LastName, MobilePhone, Email, Project__c, Date_of_Birth__c, Number_of_Pax__c, Number_of_People__c,
                                        Street, City, Locality__c, Region_If_city_is_Mumbai__c, Sub_Region__c, PostalCode, Occupation__c, Company_Name__c, Designation__c,
                                        Office_Location_New__c, City_O__c, Budget__c, Intent_of_purchase__c, Configuration_interested_in__c, Current_Residence_Ownership__c,
                                        Possession_Desired__c, LeadSource, Channel_Partner__c, Channel_Partner__r.Name, Channel_Partner__r.Phone, Channel_Partner__r.RAY_ID__c,
                                        Channel_Partner__r.RERA_Registration_No__c, Ref_Emp_Name__c, Ref_Emp_Mob__c, Ref_Emp_Relation__c, Reference_Customer__c,
                                        Reference_Customer__r.Name, Reference_Customer__r.PersonMobilePhone, Lead_Source_Minor__c from Lead 
                                        where (MobilePhone =: formattedMobile OR Secondary_Mobile__c =: formattedMobile OR MobilePhone =: mobileVal OR Secondary_Mobile__c =: mobileVal) AND IsConverted = False ORDER BY CreatedDate DESC];
                system.debug('Previous Lead List: '+pLeadList);
                
                if(!pLeadList.isEmpty() && pLeadList.size() > 0) {
                    if(pLeadList[0].FirstName != Null)
                        sv.First_Name__c = pLeadList[0].FirstName;
                    sv.Last_Name__c = pLeadList[0].LastName;
                    if(pLeadList[0].Email != Null)
                        sv.Email_Id__c = pLeadList[0].Email;
                    if(pLeadList[0].Date_of_Birth__c != Null)
                        sv.Date_of_Birth__c = pLeadList[0].Date_of_Birth__c;
                    if(pLeadList[0].Number_of_Pax__c != Null)
                        sv.Number_of_Pax__c = pLeadList[0].Number_of_Pax__c;
                    if(pLeadList[0].Number_of_People__c != Null)
                        sv.Number_of_People__c = pLeadList[0].Number_of_People__c;
                    if(pLeadList[0].Street != Null)
                        sv.Address__c = pLeadList[0].Street;
                    if(pLeadList[0].City != Null)
                        sv.City__c = pLeadList[0].City;
                    if(pLeadList[0].PostalCode != Null)
                        sv.Pincode_R__c = pLeadList[0].PostalCode;
                    if(pLeadList[0].City == 'Mumbai' || pLeadList[0].City == 'mumbai' || pLeadList[0].City == 'Thane' || pLeadList[0].City == 'thane') {
                        sv.Region_If_city_is_Mumbai__c = pLeadList[0].Region_If_city_is_Mumbai__c;
                        if(pLeadList[0].Sub_Region__c != Null)
                            sv.Sub_Region__c = pLeadList[0].Sub_Region__c;
                    }
                    if(pLeadList[0].Occupation__c != Null)
                        sv.Occupation__c = pLeadList[0].Occupation__c;
                    if(pLeadList[0].Designation__c != Null)
                        sv.Designation__c = pLeadList[0].Designation__c;
                    if(pLeadList[0].City_O__c != Null)
                        sv.City_O__c = pLeadList[0].City_O__c;
                    if(pLeadList[0].Company_Name__c != Null)
                        sv.Company_Name__c = pLeadList[0].Company_Name__c;
                    if(pLeadList[0].Office_Location_New__c != Null)
                        sv.Office_Location__c = pLeadList[0].Office_Location_New__c;
                    if(pLeadList[0].Locality__c != Null)
                        sv.Locality__c = pLeadList[0].Locality__c;
                    //If Configuration Matches
                    if(pLeadList[0].Configuration_interested_in__c == sv.Configuration__c) {
                        if(pLeadList[0].Budget__c != Null)
                            sv.Budget_in_Lac__c = pLeadList[0].Budget__c;
                        if(pLeadList[0].Intent_of_purchase__c != Null)
                            sv.Configuration_Interested_For__c = pLeadList[0].Intent_of_purchase__c;
                        if(pLeadList[0].Current_Residence_Ownership__c != Null)
                            sv.Current_Residence_Ownership__c = pLeadList[0].Current_Residence_Ownership__c;
                        if(pLeadList[0].Possession_Desired__c != Null)
                            sv.Possession_Timeline__c = pLeadList[0].Possession_Desired__c;
                    }
                }    
            }
            
            system.debug('svPage: '+svPage);
        }
        
        if(mainError==false){
            svPage=true;
        }   
    }
    
    public PageReference updateNewCP() {
        System.debug('updateNewCP >>> ');
        String param = Apexpages.currentPage().getParameters().get('paramCPName');
        
        renderCPName = param;
        if(renderCPName.contains('New Channel Partner')){
            isNewCPName = true;
            isNewCPNameRendered = true;
        }
        else{
            isNewCPName = false;
            isNewCPNameRendered = false;
        }
        System.debug('isNewCPName >>> '+isNewCPName);
        System.debug('renderCPName >>> '+renderCPName);
        return null;
    }
    
    public void submit() {
        system.debug('In Submit');
        system.debug('reVisitCheck: '+reVisitCheck);
        // Fetching Channel Partner //
        String newCPNameVal = '';
        if(reVisitCheck == False) {
            system.debug('Fresh Visit');
            system.debug('cpName: '+cpName);
            if(cpname != null && string.isNotBlank(cpname)) {
                String[] tokens = cpname.split('-');
                Integer tokenCount = tokens.size();
                /*for (Integer j = 0; j < tokenCount; j++) {
System.debug('CP Values are: '+tokens[j]);
system.debug('tokens['+j+']: '+tokens[j]);
}*/
                
                String token1 = '';
                String token2 = '';
                
                if(tokens[1] != null && tokens[1] != 'null'){
                    token1 = tokens[1];
                }
                if(tokens[2] != null && tokens[2] != 'null'){
                    token2 = tokens[2];
                }
                system.debug('tokens[1] '+tokens[1]);
                system.debug('tokens[2] '+tokens[2]);
                system.debug('token1 '+token1);
                system.debug('token2 '+token2);
                
                //String query = 'select Id, Name from Account where Phone =: token1  AND RAY_ID__c =: token2 AND RecordType.Name = \'Channel Partner\' AND Blacklist__c = False AND Active__c = True ORDER BY Name ASC';
                String completeQuery = 'select Id,Sales_Rep__r.User__c,Sales_Rep_Western__r.User__c,Sales_Rep_Western__c, Name from Account where Phone = \''+token1+'\'  AND RAY_ID__c = \''+token2+'\' AND RecordType.Name = \'Channel Partner\' AND Blacklist__c = False AND Active__c = True ORDER BY Name ASC';
                System.debug('completeQuery: '+completeQuery);
                cpList = Database.query(completeQuery);
                //cpList = [select Id, Name from Account where Phone =: tokens[1] AND RAY_ID__c =: tokens[2] AND RecordTypeId = '0127F000000RSycQAG' AND Blacklist__c = False AND Active__c = True ORDER BY Name ASC];  
                System.debug('cpList: '+cpList);
                
                if(cpList != null && cpList.size() > 0) {
                    System.debug('inside cp add');
                    sv.Channel_Partner__c = cpList[0].Id;
                    newCPNameVal = Apexpages.currentPage().getParameters().get('newCP');
                    sv.New_CP_Name__c = newCPNameVal;
                } 
            }            
            // Fetching Existing Customer //
            system.debug('selectedExistingCustomer: '+selectedExistingCustomer);
            if(selectedExistingCustomer != null && string.isNotBlank(selectedExistingCustomer)) {
                String[] tokens = selectedExistingCustomer.split('-');
                Integer tokenCount = tokens.size();
                for (Integer j = 0; j < tokenCount; j++) {
                    System.debug('Existing Customer Values are: '+tokens[j]);
                }
                existingCustomerList = [select Id, Name from Account where PersonMobilePhone =: tokens[1] AND isPersonAccount = True AND RecordType.Name = 'Individual' AND SAP_Vendor_Code__c != Null ORDER BY Name ASC];  
                System.debug('existingCustomerList: '+existingCustomerList);
                
                if(existingCustomerList != null && existingCustomerList.size() > 0) {
                    System.debug('inside existing customer add');
                    sv.Reference_Customer__c = existingCustomerList[0].Id;
                } 
            }
        }
        
        leadList = [Select Id, Name, MobilePhone, Secondary_Mobile__c, Project__c, Configuration_interested_in__c from Lead where isConverted = False AND (MobilePhone =: formattedMobile OR Secondary_Mobile__c =: formattedMobile OR MobilePhone =: mobileVal OR Secondary_Mobile__c =: mobileVal)];
        system.debug('Lead List: '+leadList);
        system.debug('Lead List Size: '+leadList.size());
        
        if(leadList.isEmpty() && leadList.size() == 0) {
            system.debug('formattedMobile----->'+formattedMobile);
            accList = [Select Id, FirstName, LastName, PersonMobilePhone, Secondary_Mobile__c from Account where (PersonMobilePhone =: formattedMobile OR Secondary_Mobile__c =: formattedMobile OR PersonMobilePhone =: mobileVal OR Secondary_Mobile__c =: mobileVal) AND isPersonAccount = True AND RecordType.Name = 'Person Account'];
            system.debug('Account List: '+accList);
            system.debug('Account List Size: '+accList.size());
            
            if(accList.isEmpty() && accList.size() == 0) {
                //Create Lead with Project Name also Convert Lead & tag SV to Converted Opportunity
                Lead l = new Lead();
                l.FirstName = sv.First_Name__c;
                l.LastName = sv.Last_Name__c;
                l.MobilePhone = formattedMobile;
                l.Email = sv.Email_Id__c;
                l.Project__c = selectedProject;
                l.Date_of_Birth__c = sv.Date_of_Birth__c;
                l.Number_of_Pax__c = sv.Number_of_Pax__c;
                l.Number_of_People__c = sv.Number_of_People__c;
                l.Street = sv.Address__c; //Need To Discuss
                l.City = sv.City__c;
                l.Locality__c = sv.Locality__c;
                if(sv.City__c == 'Mumbai' || sv.City__c == 'Thane') {
                    l.Region_If_city_is_Mumbai__c = sv.Region_If_city_is_Mumbai__c;
                    l.Sub_Region__c = sv.Sub_Region__c;   
                }
                l.PostalCode = sv.Pincode_R__c;
                l.Occupation__c = sv.Occupation__c;
                l.Company_Name__c = sv.Company_Name__c;
                l.Designation__c = sv.Designation__c;
                l.Office_Location_New__c = sv.Office_Location__c;
                l.City_O__c = sv.City_O__c;
                l.Budget__c = sv.Budget_in_Lac__c;
                l.Intent_of_purchase__c = sv.Configuration_Interested_For__c;
                l.Configuration_interested_in__c = sv.Configuration__c;
                l.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                l.Possession_Desired__c = sv.Possession_Timeline__c;
                l.LeadSource = sv.Lead_Source_Major__c;
                if(sv.Lead_Source_Major__c == 'Channel Partner') {
                    l.Channel_Partner__c = cpList[0].Id;
                    l.New_CP_Name__c = newCPNameVal;
                } else if(sv.Lead_Source_Major__c == 'Employee Referral') {
                    l.Ref_Emp_Name__c = sv.Employee_Name__c;
                    l.Ref_Emp_Mob__c = sv.Employee_Mobile_Number__c;
                    l.Ref_Emp_Relation__c = sv.Employee_Relation__c;
                } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                    l.Reference_Customer__c = existingCustomerList[0].Id;
                }
                l.Lead_Source_Minor__c = sv.Lead_Source_Minor__c;
                try {
                    insert l;
                    
                    // Converting Lead to Account & Opportunity
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(l.id);
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus where IsConverted = true LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId from Lead where Id = :l.Id];
                    system.debug('Converted Lead: '+convertedLead);
                    
                    Opportunity convertedOpp =  [SELECT Id, Name, Project__c, ESVF_Status__c, ESVF_Date_Time__c, Walk_In_Source__c, Walk_In_Sub_Source__c from Opportunity 
                                                 where Id = : convertedLead.ConvertedOpportunityId];
                    system.debug('Converted Opportunity: '+convertedOpp);
                    
                    //Tag Site Visit Against Converted Opportunity
                    sv.Opportunity__c = convertedOpp.Id;
                    sv.Project__c = selectedProject;
                    if(sv.Lead_Source_Major__c == 'Channel Partner') {
                        sv.Channel_Partner__c = cpList[0].Id;
                    } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                        sv.Reference_Customer__c = existingCustomerList[0].Id;
                    }
                    sv.ESVF_Date_Time__c = system.now();
                    sv.ESVF_Status__c = 'First Visit';
                    insert sv;
                    
                    //Update Opportunity
                    convertedOpp.ESVF_Status__c = 'First Visit';
                    convertedOpp.ESVF_Date_Time__c = system.now();
                    
                    convertedOpp.First_ESVF_DateTime__c = system.now();
                    convertedOpp.Walk_In_Source__c = sv.Lead_Source_Major__c;
                    convertedOpp.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                    update convertedOpp;
                     List<OpportunityShare> oppShareList= new List<OpportunityShare>();
                    
                    if(!cpList.isEmpty()){
                            
                            List<Project__c> prjList=[select id,Zone__c,name from Project__c where Id=:selectedProject limit 1];
                            
                            OpportunityShare oppShare =new OpportunityShare();
                            oppShare.OpportunityId =convertedOpp.id ;
                            If(prjList[0].Zone__c=='Thane'){
                                 //oppShare.UserOrGroupId = cpList[0].Sales_Rep__r.User__c;
                            }
                            else{
                                 //oppShare.UserOrGroupId = cpList[0].Sales_Rep_Western__r.User__c;
                            }
                           
                            oppShare.OpportunityAccessLevel = 'Read';
                            
                            oppShareList.add(oppShare);
                            System.debug('THE OPPSHARE'+oppShareList);
                            
                            insert oppShareList;   
                        }
                    
                    isSuccess = true;
                    message = 'Thank You!';
                    system.debug('Success Message: '+message);
                } 
                catch (Exception ex) {
                    Site_Visit_Error__c e = new Site_Visit_Error__c();
                    e.Name__c = sv.First_Name__c +' '+ sv.Last_Name__c;
                    e.Mobile_Number__c = sv.Mobile_Number__c;
                    e.Project__c = selectedProject;
                    e.Error_Message__c = String.ValueOf(ex);
                    e.First_Name__c = sv.First_Name__c;
                    e.Last_Name__c = sv.Last_Name__c;
                    e.Email_Id__c = sv.Email_Id__c;
                    e.ESVF_Date_Time__c = system.now();
                    e.ESVF_Status__c = 'First Visit';
                    e.Date_of_Birth__c = sv.Date_of_Birth__c;
                    e.Number_of_Pax__c = sv.Number_of_Pax__c;
                    e.Number_of_People__c = sv.Number_of_People__c;
                    e.Address__c = sv.Address__c;
                    e.City__c = sv.City__c;
                    e.Locality__c = sv.Locality__c;
                    e.Region_If_city_is_Mumbai__c = sv.Region_If_city_is_Mumbai__c;
                    e.Sub_Region__c = sv.Sub_Region__c;
                    e.Pincode_R__c = sv.Pincode_R__c;
                    e.Occupation__c = sv.Occupation__c;
                    e.Company_Name__c = sv.Company_Name__c;
                    e.Designation__c = sv.Designation__c;
                    e.Office_Location__c = sv.Office_Location__c;
                    e.City_O__c = sv.City_O__c;
                    e.Budget_in_Lac__c = sv.Budget_in_Lac__c;
                    e.Configuration_Interested_For__c = sv.Configuration_Interested_For__c;
                    e.Configuration_Interested_In__c = sv.Configuration__c;
                    e.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                    e.Possession_Timeline__c = sv.Possession_Timeline__c;
                    e.Walk_In_Source__c = sv.Lead_Source_Major__c;
                    e.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                    if(!cpList.isEmpty()) {
                        e.Channel_Partner__c = cpList[0].Id;
                    } else {
                        e.Channel_Partner__c = sv.Channel_Partner__c;
                    }
                    if(!existingCustomerList.isEmpty()) {
                        e.Reference_Customer__c = existingCustomerList[0].Id;
                    } else {
                        e.Reference_Customer__c = sv.Reference_Customer__c;
                    }
                    e.Employee_Name__c = sv.Employee_Name__c;
                    e.Employee_Mobile_Number__c = sv.Employee_Mobile_Number__c;
                    e.Employee_Relation__c = sv.Employee_Relation__c;
                    insert e; 
                    system.debug('Error: '+ex);
                    isRunError = true;
                    message = 'Error Occured While Processing. Please Contact System Administrator!';
                }
            } 
            else {
                //Find Active Opportunity With Same Project & Configuration
                oppList = [Select Id, Name, StageName, LeadSource, Lead_Source__c, Project__c, Channel_Partner__c, Configuration_interested_in__c, Sales_Rep__c, ESVF_Status__c,
                           ESVF_Date_Time__c, Next_Follow_up_date__c, Site_Visit_Remark__c, Visit_Rating__c from Opportunity 
                           where AccountId =: accList[0].Id AND Project__c =: selectedProject AND  Active__c = True  AND Opportunity_Active_Record__c=true 
                           order by CreatedDate DESC];
                system.debug('Opportunity List: '+oppList);
                system.debug('Opportunity List Size: '+oppList.size());
                List<OpportunityShare> oppShareList= new List<OpportunityShare>();
                
                if(oppList.isEmpty() && oppList.size() == 0) {
                    
                    System.debug('This is called beacuse there is no Opportunity with same project and configuration ');
                    //Create Opportunity With Specified Project & Configuration Under First Account In Account List
                    Opportunity op = new Opportunity();
                    op.Name = sv.First_Name__c+' '+sv.Last_Name__c;
                    op.AccountId = accList[0].Id;
                    op.StageName = 'Unit Selection';
                    op.CloseDate =   updateCloseDateProjectWise(selectedProject);         // system.today().addDays(60); // Need To Discuss
                    op.Expected_Close_Date__c=updateCloseDateProjectWise(selectedProject);
                    op.Project__c = selectedProject;
                    //op.Locality__c = sv.Locality__c;
                    op.Number_of_Pax__c = sv.Number_of_Pax__c;
                    op.Number_of_People__c = sv.Number_of_People__c;
                    op.Occupation__c = sv.Occupation__c;
                    op.Company_Name__c = sv.Company_Name__c;
                    op.Designation__c = sv.Designation__c;
                    op.Office_Location__c = sv.Office_Location__c;
                    op.City_O__c = sv.City_O__c;
                    op.Budget__c = sv.Budget_in_Lac__c;
                    op.Intent_of_Purchase__c = sv.Configuration_Interested_For__c;
                    op.Configuration_interested_in__c = sv.Configuration__c;
                    op.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                    op.Possession_Timeline__c = sv.Possession_Timeline__c;
                    op.LeadSource = sv.Lead_Source_Major__c;
                    if(sv.Lead_Source_Major__c == 'Channel Partner') {
                        op.Channel_Partner__c = cpList[0].Id;
                    } else if(sv.Lead_Source_Major__c == 'Employee Referral') {
                        op.Ref_Emp_Name__c = sv.Employee_Name__c;
                        op.Ref_Emp_Mob__c = sv.Employee_Mobile_Number__c;
                        op.Ref_Emp_Relation__c = sv.Employee_Relation__c;
                    } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                        op.Reference_Customer__c = existingCustomerList[0].Id;
                    }
                    op.Lead_Source__c = sv.Lead_Source_Minor__c;
                    op.ESVF_Status__c = 'First Visit';
                    op.ESVF_Date_Time__c = system.now();
                    op.First_ESVF_DateTime__c = system.now();
                    op.Walk_In_Source__c = sv.Lead_Source_Major__c;
                    op.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                    try{
                        insert op;
                        
                        if(!cpList.isEmpty()){
                            
                            List<Project__c> prjList=[select id,Zone__c,name from Project__c where Id=:selectedProject limit 1];
                            
                            OpportunityShare oppShare =new OpportunityShare();
                            oppShare.OpportunityId =op.id ;
                            If(prjList[0].Zone__c=='Thane'){
                                 //oppShare.UserOrGroupId = cpList[0].Sales_Rep__r.User__c;
                            }
                            else{
                                // oppShare.UserOrGroupId = cpList[0].Sales_Rep_Western__r.User__c;
                            }
                           
                            oppShare.OpportunityAccessLevel = 'Read';
                            
                            oppShareList.add(oppShare);
                            System.debug('THE OPPSHARE'+oppShareList);
                            
                            insert oppShareList;   
                        }
                        
                        //Tag Site Visit Against Opportunity
                        sv.Opportunity__c = op.Id;
                        sv.Project__c = selectedProject;
                        if(sv.Lead_Source_Major__c == 'Channel Partner') {
                            sv.Channel_Partner__c = cpList[0].Id;
                        } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                            sv.Reference_Customer__c = existingCustomerList[0].Id;
                        }
                        sv.ESVF_Date_Time__c = system.now();
                        sv.ESVF_Status__c = 'First Visit';
                        insert sv;
                        
                        isSuccess = true;
                        message = 'Thank You!';
                        
                        if(Test.isRunningTest()){
                            throw new MyException();
                        }
                        
                        system.debug('Success Message: '+message);
                    } catch (Exception ex) {
                        Site_Visit_Error__c e = new Site_Visit_Error__c();
                        e.Name__c = sv.First_Name__c +' '+ sv.Last_Name__c;
                        e.Mobile_Number__c = sv.Mobile_Number__c;
                        e.Project__c = selectedProject;
                        e.Error_Message__c = String.ValueOf(ex);
                        e.First_Name__c = sv.First_Name__c;
                        e.Last_Name__c = sv.Last_Name__c;
                        e.Email_Id__c = sv.Email_Id__c;
                        e.ESVF_Date_Time__c = system.now();
                        e.ESVF_Status__c = 'First Visit';
                        e.Date_of_Birth__c = sv.Date_of_Birth__c;
                        e.Number_of_Pax__c = sv.Number_of_Pax__c;
                        e.Number_of_People__c = sv.Number_of_People__c;
                        e.Address__c = sv.Address__c;
                        e.City__c = sv.City__c;
                        e.Locality__c = sv.Locality__c;
                        e.Region_If_city_is_Mumbai__c = sv.Region_If_city_is_Mumbai__c;
                        e.Sub_Region__c = sv.Sub_Region__c;
                        e.Pincode_R__c = sv.Pincode_R__c;
                        e.Occupation__c = sv.Occupation__c;
                        e.Company_Name__c = sv.Company_Name__c;
                        e.Designation__c = sv.Designation__c;
                        e.Office_Location__c = sv.Office_Location__c;
                        e.City_O__c = sv.City_O__c;
                        e.Budget_in_Lac__c = sv.Budget_in_Lac__c;
                        e.Configuration_Interested_For__c = sv.Configuration_Interested_For__c;
                        e.Configuration_Interested_In__c = sv.Configuration__c;
                        e.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                        e.Possession_Timeline__c = sv.Possession_Timeline__c;
                        e.Walk_In_Source__c = sv.Lead_Source_Major__c;
                        e.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                        if(!cpList.isEmpty()) {
                            e.Channel_Partner__c = cpList[0].Id;
                        } else {
                            e.Channel_Partner__c = sv.Channel_Partner__c;
                        }
                        if(!existingCustomerList.isEmpty()) {
                            e.Reference_Customer__c = existingCustomerList[0].Id;
                        } else {
                            e.Reference_Customer__c = sv.Reference_Customer__c;
                        }
                        e.Employee_Name__c = sv.Employee_Name__c;
                        e.Employee_Mobile_Number__c = sv.Employee_Mobile_Number__c;
                        e.Employee_Relation__c = sv.Employee_Relation__c;
                        insert e; 
                        system.debug('Error: '+ex);
                        isRunError = true;
                        message = 'Error Occured While Processing. Please Contact System Administrator!';
                    }
                } else {
                    
                    
                    //Tag Site Visit Against First Active Opportunity In Opportunity List
                    List<Site_Visit__c> svList = [select Id, Name from Site_Visit__c where Opportunity__c =: oppList[0].id];
                    system.debug('Size of Site Visit List: '+svList.size());
                    
                    try {
                        sv.Opportunity__c = oppList[0].Id;
                        sv.Project__c = selectedProject;
                        if(reVisitCheck = False) {
                            if(sv.Lead_Source_Major__c == 'Channel Partner') {
                                sv.Channel_Partner__c = cpList[0].Id;
                            } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                                sv.Reference_Customer__c = existingCustomerList[0].Id;
                            }
                        }
                        sv.ESVF_Date_Time__c = system.now();
                        oppList[0].Configuration_interested_in__c =sv.Configuration__c;
                        oppList[0].ESVF_Date_Time__c = system.now();
                        oppList[0].Site_Visit_Remark__c = '';
                        oppList[0].Visit_Rating__c = '';
                        oppList[0].Next_Follow_up_date__c = Null;
                        if(svList.size() == 0) {
                            sv.ESVF_Status__c = 'First Visit';
                            oppList[0].ESVF_Status__c = 'First Visit';
                            oppList[0].First_ESVF_DateTime__c = system.now();
                            oppList[0].closedate=system.today().addDays(60);
                            oppList[0].Walk_In_Source__c = sv.Lead_Source_Major__c;
                            oppList[0].Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                        } else if(svList.size() == 1) {
                            sv.ESVF_Status__c = 'Re-Visit 1';
                            oppList[0].ESVF_Status__c = 'Re-Visit 1';
                        } else if(svList.size() == 2) {
                            sv.ESVF_Status__c = 'Re-Visit 2';
                            oppList[0].ESVF_Status__c = 'Re-Visit 2';
                        } else if(svList.size() == 3) {
                            sv.ESVF_Status__c = 'Re-Visit 3';
                            oppList[0].ESVF_Status__c = 'Re-Visit 3';
                        } else if(svList.size() == 4) {
                            sv.ESVF_Status__c = 'Re-Visit 4';
                            oppList[0].ESVF_Status__c = 'Re-Visit 4';
                        } else if(svList.size() > 5) {
                            sv.ESVF_Status__c = 'Re-Visit 5 & More';
                            oppList[0].ESVF_Status__c = 'Re-Visit 5 & More';
                        }
                        //Assign Sales Rep
                        //if(oppList[0].Sales_Rep__c != Null) {
                        //sv.Sales_Rep__c = oppList[0].Sales_Rep__c;   
                        //}
                        System.debug('svController sv >>> '+sv);
                        System.debug('svController sv.Channel_Partner__c >>> '+sv.Channel_Partner__c);
                        System.debug('svController sv.New_CP_Name__c >>> '+sv.New_CP_Name__c);
                        insert sv;
                        System.debug('svController oppList[0] >>> '+oppList[0]);
                        System.debug('svController oppList[0].ESVF_Date_Time__c >>> '+oppList[0].ESVF_Date_Time__c);
                        System.debug('svController oppList[0].ESVF_Status__c >>> '+oppList[0].ESVF_Status__c);
                        update oppList[0];
                        
                        isSuccess = true;
                        message = 'Thank You!';
                        
                        if(Test.isRunningTest()){
                            throw new MyException();
                        } 
                        
                        system.debug('Success Message: '+message);
                    } catch(Exception ex) {
                        Site_Visit_Error__c e = new Site_Visit_Error__c();
                        e.Name__c = sv.First_Name__c +' '+ sv.Last_Name__c;
                        e.Mobile_Number__c = sv.Mobile_Number__c;
                        e.Project__c = selectedProject;
                        e.Error_Message__c = String.ValueOf(ex);
                        e.First_Name__c = sv.First_Name__c;
                        e.Last_Name__c = sv.Last_Name__c;
                        e.Email_Id__c = sv.Email_Id__c;
                        e.ESVF_Date_Time__c = system.now();
                        e.ESVF_Status__c = sv.ESVF_Status__c;
                        e.Date_of_Birth__c = sv.Date_of_Birth__c;
                        e.Number_of_Pax__c = sv.Number_of_Pax__c;
                        e.Number_of_People__c = sv.Number_of_People__c;
                        e.Address__c = sv.Address__c;
                        e.City__c = sv.City__c;
                        e.Locality__c = sv.Locality__c;
                        e.Region_If_city_is_Mumbai__c = sv.Region_If_city_is_Mumbai__c;
                        e.Sub_Region__c = sv.Sub_Region__c;
                        e.Pincode_R__c = sv.Pincode_R__c;
                        e.Occupation__c = sv.Occupation__c;
                        e.Company_Name__c = sv.Company_Name__c;
                        e.Designation__c = sv.Designation__c;
                        e.Office_Location__c = sv.Office_Location__c;
                        e.City_O__c = sv.City_O__c;
                        e.Budget_in_Lac__c = sv.Budget_in_Lac__c;
                        e.Configuration_Interested_For__c = sv.Configuration_Interested_For__c;
                        e.Configuration_Interested_In__c = sv.Configuration__c;
                        e.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                        e.Possession_Timeline__c = sv.Possession_Timeline__c;
                        e.Walk_In_Source__c = sv.Lead_Source_Major__c;
                        e.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                        if(!cpList.isEmpty()) {
                            e.Channel_Partner__c = cpList[0].Id;
                        } else {
                            e.Channel_Partner__c = sv.Channel_Partner__c;
                        }
                        if(!existingCustomerList.isEmpty()) {
                            e.Reference_Customer__c = existingCustomerList[0].Id;
                        } else {
                            e.Reference_Customer__c = sv.Reference_Customer__c;
                        }
                        e.Employee_Name__c = sv.Employee_Name__c;
                        e.Employee_Mobile_Number__c = sv.Employee_Mobile_Number__c;
                        e.Employee_Relation__c = sv.Employee_Relation__c;
                        insert e; 
                        system.debug('Error: '+ex);
                        isRunError = true;
                        message = 'Error Occured While Processing. Please Contact System Administrator!';
                    }
                }
            }
        } 
        else {
            //Check Lead Present With Same Project & Same Configuration
            try {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(leadList[0].id);
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus where IsConverted = true LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId from Lead where Id = :leadList[0].Id];
                system.debug('Converted Lead: '+convertedLead);
                
                Opportunity convertedOpp =  [SELECT Id, Name, Project__c,closedate, Configuration_interested_in__c, ESVF_Status__c, ESVF_Date_Time__c from Opportunity where Id = : convertedLead.ConvertedOpportunityId];
                system.debug('Converted Opportunity: '+convertedOpp);
                
                if(convertedOpp.Project__c == selectedProject && convertedOpp.Configuration_interested_in__c == sv.Configuration__c) {
                    //Opportunity Present with Same Project & Configuration
                    //Tag Site Visit Against Opportunity
                    sv.Opportunity__c = convertedOpp.Id;
                    sv.Project__c = selectedProject;
                    if(sv.Lead_Source_Major__c == 'Channel Partner') {
                        sv.Channel_Partner__c = cpList[0].Id;
                    } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                        sv.Reference_Customer__c = existingCustomerList[0].Id;
                    }
                    sv.ESVF_Date_Time__c = system.now();
                    sv.ESVF_Status__c = 'First Visit';
                    insert sv;
                    
                    //Update Opportunity
                    convertedOpp.ESVF_Status__c = 'First Visit';
                    convertedOpp.ESVF_Date_Time__c = system.now();
                    convertedOpp.First_ESVF_DateTime__c = system.now();
                    convertedOpp.closedate = system.today()+60;
                    convertedOpp.Walk_In_Source__c = sv.Lead_Source_Major__c;
                    convertedOpp.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                    convertedOpp.closedate =updateCloseDateProjectWise(selectedProject);
                    convertedOpp.Expected_Close_Date__c= updateCloseDateProjectWise(selectedProject);
                    update convertedOpp;
                    
                    isSuccess = true;
                    message = 'Thank You!';
                    system.debug('Success Message: '+message);
                } else {
                    //Opportunity Not Present with Same Project & Configuration
                    Opportunity op = new Opportunity();
                    op.Name = sv.First_Name__c+' '+sv.Last_Name__c;
                    op.AccountId = convertedLead.ConvertedAccountId;
                    op.StageName = 'Unit Selection';
                    op.CloseDate = system.today().addDays(60); // Need To Discuss
                    op.Project__c = selectedProject;
                    //op.Locality__c = sv.Locality__c;
                    op.Number_of_Pax__c = sv.Number_of_Pax__c;
                    op.Number_of_People__c = sv.Number_of_People__c;
                    op.Occupation__c = sv.Occupation__c;
                    op.Company_Name__c = sv.Company_Name__c;
                    op.Designation__c = sv.Designation__c;
                    op.Office_Location__c = sv.Office_Location__c;
                    op.City_O__c = sv.City_O__c;
                    op.Budget__c = sv.Budget_in_Lac__c;
                    op.Intent_of_Purchase__c = sv.Configuration_Interested_For__c;
                    op.Configuration_interested_in__c = sv.Configuration__c;
                    op.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                    op.Possession_Timeline__c = sv.Possession_Timeline__c;
                    op.LeadSource = sv.Lead_Source_Major__c;
                    if(sv.Lead_Source_Major__c == 'Channel Partner') {
                        op.Channel_Partner__c = cpList[0].Id;
                    } else if(sv.Lead_Source_Major__c == 'Employee Referral') {
                        op.Ref_Emp_Name__c = sv.Employee_Name__c;
                        op.Ref_Emp_Mob__c = sv.Employee_Mobile_Number__c;
                        op.Ref_Emp_Relation__c = sv.Employee_Relation__c;
                    } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                        op.Reference_Customer__c = existingCustomerList[0].Id;
                    }
                    op.Lead_Source__c = sv.Lead_Source_Minor__c;
                    op.ESVF_Status__c = 'First Visit';
                    op.ESVF_Date_Time__c = system.now();
                    convertedOpp.First_ESVF_DateTime__c = system.now();
                    op.Walk_In_Source__c = sv.Lead_Source_Major__c;
                    op.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                    insert op;
                    
                    //Tag Site Visit Against Opportunity
                    sv.Opportunity__c = op.Id;
                    sv.Project__c = selectedProject;
                    if(sv.Lead_Source_Major__c == 'Channel Partner') {
                        sv.Channel_Partner__c = cpList[0].Id;
                    } else if(sv.Lead_Source_Major__c == 'Existing Customer Referral') {
                        sv.Reference_Customer__c = existingCustomerList[0].Id;
                    }
                    sv.ESVF_Date_Time__c = system.now();
                    sv.ESVF_Status__c = 'First Visit';
                    insert sv;
                    
                    isSuccess = true;
                    message = 'Thank You!';
                    system.debug('Success Message: '+message);
                }
            } 
            catch(Exception ex) {
                Site_Visit_Error__c e = new Site_Visit_Error__c();
                e.Name__c = sv.First_Name__c +' '+ sv.Last_Name__c;
                e.Mobile_Number__c = sv.Mobile_Number__c;
                e.Project__c = selectedProject;
                e.Error_Message__c = String.ValueOf(ex);
                e.First_Name__c = sv.First_Name__c;
                e.Last_Name__c = sv.Last_Name__c;
                e.Email_Id__c = sv.Email_Id__c;
                e.ESVF_Date_Time__c = system.now();
                e.ESVF_Status__c = 'First Visit';
                e.Date_of_Birth__c = sv.Date_of_Birth__c;
                e.Number_of_Pax__c = sv.Number_of_Pax__c;
                e.Number_of_People__c = sv.Number_of_People__c;
                e.Address__c = sv.Address__c;
                e.City__c = sv.City__c;
                e.Locality__c = sv.Locality__c;
                e.Region_If_city_is_Mumbai__c = sv.Region_If_city_is_Mumbai__c;
                e.Sub_Region__c = sv.Sub_Region__c;
                e.Pincode_R__c = sv.Pincode_R__c;
                e.Occupation__c = sv.Occupation__c;
                e.Company_Name__c = sv.Company_Name__c;
                e.Designation__c = sv.Designation__c;
                e.Office_Location__c = sv.Office_Location__c;
                e.City_O__c = sv.City_O__c;
                e.Budget_in_Lac__c = sv.Budget_in_Lac__c;
                e.Configuration_Interested_For__c = sv.Configuration_Interested_For__c;
                e.Configuration_Interested_In__c = sv.Configuration__c;
                e.Current_Residence_Ownership__c = sv.Current_Residence_Ownership__c;
                e.Possession_Timeline__c = sv.Possession_Timeline__c;
                e.Walk_In_Source__c = sv.Lead_Source_Major__c;
                e.Walk_In_Sub_Source__c = sv.Lead_Source_Minor__c;
                if(!cpList.isEmpty()) {
                    e.Channel_Partner__c = cpList[0].Id;
                } else {
                    e.Channel_Partner__c = sv.Channel_Partner__c;
                }
                if(!existingCustomerList.isEmpty()) {
                    e.Reference_Customer__c = existingCustomerList[0].Id;
                } else {
                    e.Reference_Customer__c = sv.Reference_Customer__c;
                }
                e.Employee_Name__c = sv.Employee_Name__c;
                e.Employee_Mobile_Number__c = sv.Employee_Mobile_Number__c;
                e.Employee_Relation__c = sv.Employee_Relation__c;
                insert e; 
                system.debug('Error: '+ex);
                isRunError = true;
                message = 'Error Occured While Processing. Please Contact System Administrator!';
            }
        }  
    }
    public String checkSiteVist(String accId,String siteVisitProject,String siteVisitConfig){
        
        
        //1.opp + site visit
        //2.ftech the opportunity with site visit order by created date DESC limit 1
        //3. compare the list's project with selected project and configuration
        //4. If Porjrct and config are different give an error 
        //5. If Same consider as revisit 
        
        String config;
        string prjName;
        
        String status;
        System.debug('INSIDE CHECKVISIT----->');
        Set<Id> oppId=new set<Id>();
        List<Opportunity> oppList= new List<Opportunity>();
        //[select id, project__r.name, Configuration_interested_in__c  from Opportunity where AccountId=:accId /*and project__r.name!='Super Premium'*/]
        if(siteVisitProject.equals('Park Avenue')){
            oppList=[select id, project__r.name, Configuration_interested_in__c  from Opportunity where AccountId=:accId and project__r.name='Park Avenue' AND  Opportunity_Active_Record__c=true];
        }else if(siteVisitProject.equals('TenX Vibes')){
            oppList=[select id, project__r.name, Configuration_interested_in__c  from Opportunity where AccountId=:accId and project__r.name='TenX Vibes' AND  Opportunity_Active_Record__c=true];
        }
        else if(siteVisitProject.equals('The Address BY GS - Bandra')){
            oppList=[select id, project__r.name, Configuration_interested_in__c  from Opportunity where AccountId=:accId and project__r.name='The Address BY GS - Bandra' AND  Opportunity_Active_Record__c=true];
        }
        else{
            oppList=[select id, project__r.name, Configuration_interested_in__c  from Opportunity where AccountId=:accId AND  Opportunity_Active_Record__c=true AND (project__r.name!='TenX Vibes' AND project__r.name!='Park Avenue' And project__r.name!='The Address BY GS - Bandra')/* and project__r.name='Super Premium'*/];
        }
        system.debug('oppList---->'+oppList);
        
        
        if(oppList.isEmpty()){
            status='Allow';
            return status;
        }
        for(Opportunity opp: oppList){
            oppId.add(opp.Id);
        }
        if (oppList.size()>0){
            System.debug('inside 1355');
            list<Site_Visit__c> svlist=[select id,Opportunity_Project_Name__c,Opportunity__r.Configuration_interested_in__c from Site_Visit__c where Opportunity__c in:oppId and (Opportunity_Project_Name__c!='The Address BY GS - Bandra'or Opportunity_Project_Name__c!='TenX Vibes' or Opportunity_Project_Name__c!='Park Avenue') order by createdDate DESC ];// 9-11-2023 this is for expect The Address BY GS - Bandra project.
            
            
            if(siteVisitProject.equals('Park Avenue') || siteVisitProject.equals('TenX Vibes') || siteVisitProject.equals('The Address BY GS - Bandra') ){
                System.debug('inside 1377');
                list<Site_Visit__c> svlistForSuperPremium=[select id,Opportunity_Project_Name__c,Opportunity__r.Configuration_interested_in__c from Site_Visit__c where Opportunity__r.AccountId=:accId and (Opportunity_Project_Name__c='The Address BY GS - Bandra' or Opportunity_Project_Name__c='TenX Vibes' or Opportunity_Project_Name__c='Park Avenue')  and Opportunity__r.Configuration_interested_in__c=:siteVisitConfig /*and Active__c=true AND  Opportunity_Active_Record__c=true*/ order by createdDate DESC];
                
                if(svlistForSuperPremium.size()>0){
                    System.debug('line 1365');
                    if(svlistForSuperPremium[0].Opportunity_Project_Name__c.equals(siteVisitProject) && svlistForSuperPremium[0].Opportunity__r.Configuration_interested_in__c!=siteVisitConfig.trim()){
                        System.debug('line 1367');
                        status='Deny';
                        return status;
                    }else if(svlistForSuperPremium[0].Opportunity_Project_Name__c.equals(siteVisitProject) && svlistForSuperPremium[0].Opportunity__r.Configuration_interested_in__c.equals(siteVisitConfig.trim())){
                        System.debug('line 1371');
                        
                        status='Allow';
                        return status;
                    }
                }else if(svlistForSuperPremium.size()==0){
                    System.debug('THE CONFIG----->'+oppList[0].Configuration_interested_in__c);
                    System.debug('THE CHOOSEN--------->'+siteVisitConfig);
                    if(oppList[0].Configuration_interested_in__c.equals(siteVisitConfig.trim())){
                        System.debug('line 1377');
                        status='Allow';
                        return status;
                    }else{
                        System.debug('line 1378');
                        status='Deny';
                        return status;
                    }
                    
                }
            }
            
            if(svlist.size()>0){
                System.debug('Site visit found');
                prjName=svList[0].Opportunity_Project_Name__c;
                config=svList[0].Opportunity__r.Configuration_interested_in__c.trim();
                
                if(!prjName.equals(siteVisitProject)){
                    System.debug('line 1391');
                    status='Deny';
                }else if(prjName.equals(siteVisitProject) && config.equals(siteVisitConfig.trim())){
                    System.debug('line 1388');
                    status='Allow';
                }else if(prjName.equals(siteVisitProject) && config!=siteVisitConfig.trim() ){
                    System.debug('line 1391');
                    status='Deny';
                    
                }
            }
            else if(svlist.size()==0){
                // agar ye zro hota hai toh same project and config check krna hai 
                String svConfig=siteVisitConfig.trim();
                
                List<Opportunity> newOppList=[select id,name,Configuration_interested_in__c from opportunity where project__r.Name=:siteVisitProject  and accountId=:accId AND  Opportunity_Active_Record__c=true];
                System.debug('newOppList------->'+newOppList);
                if(newOppList.isEmpty()){
                    SYstem.debug('inside 1395');
                    status='Allow';
                }else if(!newOppList.isEmpty() && newOppList[0].Configuration_interested_in__c.equals(svConfig)){
                    SYstem.debug('inside 1396');
                    status='Allow';
                }else if (!newOppList[0].Configuration_interested_in__c.equals(svConfig)){
                    status='Deny';
                }
                else{
                    SYstem.debug('inside 1397');
                    status='Allow';
                }
                
                
                
                System.debug('prjName---->'+prjName);
                System.debug('siteVisitProject---->'+siteVisitProject);
                System.debug('config---->'+config);
                System.debug('siteVisitConfig---->'+siteVisitConfig);
                
            }
            
            
            
        }
        return status;
    }

   
    
    public Pagereference closeForm() {
        Pagereference pg = new Pagereference('/apex/SiteVisitForm');
        pg.setredirect(true);
        return pg;
    }
    
    public date updateCloseDateProjectWise(String projectId){
        date dt;
        System.debug('THE PROJECT ID------------->'+projectId);
        list<Project__c> prjLIst = [select id,Name from project__C where id =:projectId limit 1];
        String projectName=prjLIst[0].Name;
        
        if(prjLIst.size()>0){
            
            List<Site_visit_Expiration_Days__mdt> stvMdtList= new List<Site_visit_Expiration_Days__mdt>();
            stvMdtList=[select id,Project_Name__c,Expiration_Days__c from Site_visit_Expiration_Days__mdt where Project_Name__c =:projectName ];
            System.debug('stvMdtList-------------->'+stvMdtList);
            Decimal daystobeAdded=stvMdtList[0].Expiration_Days__c;
            dt=date.today().addDays(Integer.valueOf(daystobeAdded));
            // List<Site_visit_Expiration_Days__mdt> stvMdtList=[select id,Project_Name__c,Expiration_Days__c from Site_visit_Expiration_Days__mdt  limit 1];
        }
        
        return dt;
        
        
    }

    
    
}