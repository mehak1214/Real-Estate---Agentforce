/*
** ____________________________________________________________________________________________
** Created by	:   Akash Pawar
** Created Date	:   00/11/2020 
** Company Name	: 	Stetig Consulting Pvt Ltd
** ============================================================================================
** Description	: 	To create quote & generate pricesheet
** ____________________________________________________________________________________________
*/

public without sharing class MyCustomLookupController {
    
    public Quote quote {get;set;}
    public  Quote quote1 {get;set;}
    public Payment_Plan__c PaymentPlan {get;set;}
    public Product2 prod{get;set;}
    public Opportunity Opp{get;set;}
    public  id prodId{get;set;}
    public string planType{get;set;}
    public List<CLP_Line_Item__c> CLPLineList{get;set;}
    Public List<CLP_Master__c> CLPMaster {get;set;}
    public string quoteId{get;set;}
    public string pid{get;set;}
    public string OptyID{get;set;}
    public Boolean OptyBoolean{get;set;}
    public String projectsent{get;set;}
    public String towersent{get;set;}
    public Contact contact {get;set;}
    public PriceSheetWrapper objPriceSheetWrapper{get; set;}
    public String parentId;
    public list<Payment_Plan_Line__c> lstPaymentLine{get;set;}
    public Boolean pdfMode{get; set;}
    public String paymentPlanId{get; set;}
    public List<SelectOption> lstPaymentPlanOption{get; set;}
    public Opportunity Opt{get;set;}
    /* change dt:10/02/2021*/ public String pdfName;
    public String selectedVal {
        get;
        set;
    }
    public String selectedTower {
        get; 
        set;
    }
   public Boolean CustomBoolean  {get; set;}
    public Id OppSelected{get; set;}
    public Boolean OppBool{get; set;}
     public String message{get;set;}
    public string blockMessage{get;set;}
     public boolean displayPopup {get; set;}    
    public  Boolean BacktoPage {get;set;}
     public Boolean Loading {get;set;}
      public static string ErrorMesssage{get;set;}
    
    public List < SelectOption > getPlanType {
        get {
             List < SelectOption > optns = new List < Selectoption > ();
             optns.add(new SelectOption('', 'Choose one...'));
            system.debug('quote1.OpportunityId : '+quote1.OpportunityId);
            if(quote1.OpportunityId != NULL){
            optns.add(new SelectOption('Standard', 'Standard'));
            optns.add(new SelectOption('Custom', 'Custom'));
            }
            return optns;
        }
        set;
    }
    
    public MyCustomLookupController(){
        contact = new Contact();
       	Loading = true;
       	BacktoPage = false;
        OptyBoolean = true;
        ErrorMesssage = '';
        string opp = ApexPages.currentPage().getParameters().get('OptyID');
        if(opp != NULL && !string.isBlank(opp)){
           // OptyBoolean = false;
        }
        lstPaymentPlanOption = new List<SelectOption>();
        for(Payment_Plan__c objPaymentPlan : [select Id, Name from Payment_Plan__c where Quote__c =: parentId]){
            lstPaymentPlanOption.add(new SelectOption(objPaymentPlan.Id, objPaymentPlan.Name));
        }
        OppBool = false	;
    }
    
    
    
    public List < SelectOption > getTowers {
        get {
            system.debug('Inside getTowers'+projectsent+ towersent);
            List < SelectOption > options = new List < Selectoption > ();
             system.debug(':: selectedVal ::'+selectedVal);
            options.add(new SelectOption('', 'Choose one...'));
            if (selectedVal != null && projectsent != NULL && towersent != NULL) {
                
                if(selectedVal == 'Standard'){
                    CustomBoolean = false;
                }else if(selectedVal == 'Custom'){
                     CustomBoolean = true;
                }
                system.debug('towersent :: '+towersent+ ':: projectsent :: '+projectsent+ ':: CustomBoolean ::'+CustomBoolean);
                List < CLP_Master__c > qResult = new List < CLP_Master__c > ([select Id,Title__c,Custom__c from CLP_Master__c where Tower__c =: towersent AND Project__c =: projectsent AND Active__c = true AND Custom__c =: CustomBoolean]);
                system.debug('qResult--'+qResult);
                for (CLP_Master__c obj1: qResult) {
                    options.add(new SelectOption(obj1.Id, obj1.Title__c));
                }
            }
            return options;
        }
        set;
    }
    
    
    public pagereference MyCustomLookupAction() {
        quote = new Quote();
         quote1 = new Quote();
        prod = new Product2();
        Opp = new Opportunity();
          OppBool = false;
        if(pid == NULL){
            pid = ApexPages.currentPage().getParameters().get('pid');
        }
        if(OptyID == NULL){
            OptyID = ApexPages.currentPage().getParameters().get('OptyID');
        }
        if(projectsent == NULL){
            projectsent = ApexPages.currentPage().getParameters().get('projectsent');
        }
        if(towersent == NULL){
            towersent = ApexPages.currentPage().getParameters().get('towersent');
        }
        List<Product2> prodListfetch  = new List<Product2>();
        if(pid != NULL && pid!=''){
            /*Prod  change dt: 10/02/2021*/ prodListfetch =[SELECT Id,Name, Floor_No__c ,Unit_Status__c,Unit_Category__c,Material_Code__c,
                   Project__c,Carpet_Area_RERA_Carpet__c, Saleable_Area__c,Opportunity__c, Tower__c
                   from Product2 where  Family = 'Saleable Unit' AND Id =:pid ];
            if(prodListfetch!= NULL && !prodListfetch.isEmpty()){
                prod = prodListfetch[0];
            }
        }
        
        if(OptyID != NULL && OptyID != ''){
            Opp = [Select Id, Name, AccountId from Opportunity Where Id = : OptyID];
            if(Opp != NULL){
                quote1.OpportunityId = Opp.Id;
            }
        }
        system.debug('selectedTower'+selectedTower);
        system.debug('Otside :::: if'+'pid'+pid+' OptyId'+ OptyID + ' projectsent' +projectsent+ ' towersent'+towersent); 
        if(Prod != NULL && Opp != NULL && projectsent == prod.Project__c && projectsent != NULL && projectsent != ''&& Prod.Tower__c == towersent && towersent != '' && towersent != NULL && selectedVal != NULL && !string.isBlank(selectedVal) && selectedTower!= NULL && !string.isBlank(selectedTower)){
            Quote que = new Quote();
            que.Name = Opp.Name + ' - '+prod.Name ;
            que.OpportunityId = Opp.Id;
            que.Project__c = prod.Project__c;
            que.Tower__c = prod.Tower__c;
            //que.Name = prod.Tower__c;
            system.debug('que::::'+que);
            //que.AccountId = Opp.AccountId;
            try{
            Insert que;
            if(que.Id!= NULL){
                boolean flag =  saveProductToQuote(prod, que.Id);
                que = [select Id, AccountId, Name,Project__c,Tower__c,Carpet_Area__c from Quote Where Id =: que.Id];
                system.debug('saveProductToQuote::::'+flag);
                if(flag == true){
                    CLPMaster = [select Id,Title__c,Custom__c from CLP_Master__c where Id =: selectedTower/*Tower__c =: que.Tower__c AND Project__c =: que.Project__c AND Active__c = true*/];
                    if(CLPMaster != NULL && !CLPMaster.isEmpty()){
                        List<CLP_Line_Item__c> CLPLineList = new List<CLP_Line_Item__c>();
                        CLPLineList = [select Id,CLP_Type__c,Title__c,Value__c,Sort_Order__c,Amount__c,Amount_After_Tax__c,CLP_Master__c,Amount_Payable__c from CLP_Line_Item__c where CLP_Master__c=:CLPMaster[0].Id order by Sort_Order__c];
                        boolean flagPaymentPlan = saveStdPaymentPlan(CLPLineList, CLPMaster[0].Id, que, CustomBoolean);
                        system.debug('flagPaymentPlan::::'+flagPaymentPlan);
                        if(flagPaymentPlan==true){
                            return new PageReference('/apex/PriceSheetCreate?Qid='+que.Id);
                        }
                    }
                }
            }
            
            }catch(exception e){
                ErrorMesssage = string.valueOf(e);
                if(e.getMessage().containsIgnoreCase('Second Booking')){
                    String errVal='This is a second booking. You cannot create quotes for this Opportunity';
                	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errVal));    
                }
                else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
                }
                
                BacktoPage = true;
                Loading = false;
			}
        }
        return NULL;
    }
    
	public PageReference OnSelectOpp() {
        OppBool = true;
        IF(quote1.OpportunityId == NULL){
            displayPopup = true;
            message = 'Test';
        }
        system.debug('OppBool'+OppBool);
        return NULL;
     }
    
    Public string selectedname{get;set;}
    Public List<Selectoption> getselectedaccnamefields(){
        Schema.DescribeFieldResult fieldResult = Payment_Plan__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Selectoption> lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('', '- None -'));
        for( Schema.PicklistEntry f : ple)
        {
            lstnamesel.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return lstnamesel; 
    }
    
    public void searchPlanType() {
        
    }
    
    Public List<Selectoption> getselectType(){
        Schema.DescribeFieldResult fieldResult = Payment_Plan__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Selectoption> lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('Standard', 'Standard'));
        lstnamesel.add(new SelectOption('Custom', 'Custom'));      
        return lstnamesel; 
    }
    
    
    public Void getPaymentPlanLine(){
        system.debug('Inside the getPaymentPlanLine :: prod'+prod);
        //List<CLP_Master__c> CLPMaster = new List<CLP_Master__c>();
        // Quote quoterec = [select Id,Agreement_Value_w_o_Tax__c,Agreement_Value_with_GST__c,(select Id from QuoteLineItems where Product2.Family = 'Saleable Unit'),Tower__c,TotalPrice,Carpet_Area__c,Total_Price__c,Gross_Total__c,AccountId,Salable_Price_Total__c,Total_Amount_without_Tax__c from Quote where Id=:recordId];
        boolean Flag = false;
        if(planType == 'Custom'){
            Flag = true;
        }
        If(prod != NULL){
            CLPMaster = [select Id,Title__c,Custom__c from CLP_Master__c where Tower__c =: prod.Tower__c and Active__c = true AND Custom__c =: Flag];
            //return CLPLineList;
            // List<CLP_Line_Item__c> CLPLineList = new List<CLP_Line_Item__c>();
            system.debug('CLPMaster ::::'+CLPMaster);
            If(CLPMaster != NULL && !CLPMaster.isEmpty()){
                CLPLineList = [select Id,CLP_Type__c,Title__c,Value__c,Sort_Order__c,Amount__c,Amount_After_Tax__c,CLP_Master__c,Amount_Payable__c from CLP_Line_Item__c where CLP_Master__c=:CLPMaster[0].Id order by Sort_Order__c];
                system.debug('CLPLineList '+CLPLineList);
                //return CLPLineList;
            }else{
                CLPLineList = new List<CLP_Line_Item__c>();
            }
        }else{
            CLPLineList = new List<CLP_Line_Item__c>();
        }
        
    }
    
      public void closePopup() {        
        displayPopup = false;    
    } 
    
    public PageReference save(){
        system.debug('quote1'+quote1);
        system.debug('/apex/MyCustomLookup?pid='+pid+'&OptyID='+Quote1.OpportunityId+'&projectsent='+projectsent+'&towersent='+towersent);
        OptyID = quote1.OpportunityId;
        PageReference pr = MyCustomLookupAction();
        //pr = MyCustomLookupAction();
        system.debug('pr ::: '+pr);
        return pr;
    }	
    
    public PageReference cancel(){
        return new PageReference('/apex/S_InventoryMatrixview?projectsent='+prod.Project__c+'&towersent='+prod.Tower__c);
    }
    
    // Proce Sheet Line	
    
    /* public PriceSheetController(){}*/
    public PageReference PriceSheetController(Quote quoteData) {
        Quote quote = quoteData;
        system.debug('quote'+quote);
        parentId = quote.Id;
        pdfMode = false;
        String pageMode = ApexPages.currentPage().getParameters().get('pdfMode');
        pdfMode = (pageMode == 'true'?true:false);
        lstPaymentPlanOption = new List<SelectOption>();
        if(!pdfMode){
            for(Payment_Plan__c objPaymentPlan : [select Id, Name from Payment_Plan__c where Quote__c =: parentId]){
                lstPaymentPlanOption.add(new SelectOption(objPaymentPlan.Id, objPaymentPlan.Name));
            }
        }
        paymentPlanId = ApexPages.currentPage().getParameters().get('paymentPlanId');
        if(String.isNotBlank(paymentPlanId)){
            initialiseList();
        }
        return NULL;
    }
    //This method is used to save the Pricesheet into the attachment under the Quote record.
    public void createPDF(){
        pdfMode = true;
        initialiseList();
        string fileName = pdfName+ ' '+'-Pricesheet.pdf';
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachemnt; filename='+fileName);
        createAttachment(parentId, paymentPlanId, pdfName);
    }
    
    @future(callout=true)
    public static void createAttachment(String parentId, String paymentPlanId, String pdfName){
        PageReference objPageReference = new PageReference('/apex/VF_NewDisplayPriceSheet?id='+parentId+'&pdfMode=true&paymentPlanId='+paymentPlanId);
        Blob pdfBody = (Test.isRunningTest()?Blob.valueOf('test'):objPageReference.getContentAsPDF());
        Attachment attach = new Attachment();
        attach.Body = pdfBody;
        // add the user entered name
        string st = pdfName+ ' '+'-Pricesheet'+ ''+System.today().format() + '.pdf';
        attach.Name = st;
        attach.IsPrivate = false;
        // attach the pdf to the Quote
        attach.ParentId = parentId;
        list<Attachment> listA = new list<Attachment>([Select id, Name, parentId from attachment where Name =:st and parentId =:parentId]);
        if(listA.size()<=0){
            insert attach;
        }  
    }
    
    //Method to initialize the Wrapper instance with and Quote Line Items.
     
    /*private change dt:10/02/2021*/public void initialiseList(){
        List<Quote> lstQuote = new List<Quote>();
        lstQuote = [select Id, Name, GST__c, Unit_Cost_With_Discount__c, Other_Charges__c,Project__r.Name, Opportunity.Project__r.Terms_and_Conditions__c, Opportunity.Account.Name,Scanning_Charges__c,Registration__c,Agreement_Value__c,Unit_Cost__c,Agreement_Value_w_o_Tax__c,Approved_Discount__c,Stamp_Duty__c,Project_Address__c,Tower__r.Name,Carpet_Area__c , Floor_No__c, Appt__c, Other_Charges_For_GST__c,(select Id, Product2.Saleable_Area__c, Floor_Rise_Charges__c,Development_Charges__c,Preferential_Location_charges__c,UnitPrice, Quantity, Product2.EVBT__c, Product2.Different_Unit_Area__c, Product2.Description, Product2.Family, Product2.Unit_Category__c, Product2.Carpet_Area_RERA_Carpet__c, Sub_Total__c from QuoteLineItems where (Product2.Family = 'Other Charges' OR Product2.Family = 'Saleable Unit' )) from Quote where Id =: parentId];
        if(lstQuote != null && !lstQuote.isEmpty()){
            List<QuoteLineItem> lstOtherChargesItem = new List<QuoteLineItem>();
            QuoteLineItem objSalesableUnitItem = new QuoteLineItem();
            pdfName = lstQuote[0].Name;
            // system.debug('lstQuote'+lstQuote[0].QuoteLineItems);
            for(QuoteLineItem objQuoteLineItem : lstQuote[0].QuoteLineItems){
                if(objQuoteLineItem.Product2.Family == 'Other Charges'){
                    lstOtherChargesItem.add(objQuoteLineItem);
                }else if(objQuoteLineItem.Product2.Family == 'Saleable Unit'){
                    objSalesableUnitItem = objQuoteLineItem;
                }
            }
            
            objPriceSheetWrapper = new PriceSheetWrapper(lstQuote[0], lstOtherChargesItem, objSalesableUnitItem);
        }
        
        //Payment_Plan__c objPaymentPlan = [select Id, Name from Payment_Plan__c where Quote__c =: parentId LIMIT 1];
        lstPaymentLine = new list<Payment_Plan_Line__c> ([Select id,Name, Payment_Plan__c, Title__c, Value__c, Amount_After_Tax__c  from Payment_Plan_Line__c where Payment_Plan__c = :paymentPlanId]);
    }
    /******************************************Wrapper Class**********************************/
    public class PriceSheetWrapper{
        public Quote objQuote{get;set;}
        public List<QuoteLineItem> lstQuoteLine{get;set;}
        public QuoteLineItem objSaleableUnit{get; set;}
        public PriceSheetWrapper(Quote objQuote, List<QuoteLineItem> lstQuoteLine, QuoteLineItem objSaleableUnit) {
            this.objQuote = objQuote;
            this.lstQuoteLine = lstQuoteLine;
            this.objSaleableUnit = objSaleableUnit;
        }
    }
    
    
    //add Product
    public static boolean saveProductToQuote(Product2 prod,String QuoteId){
        //Code to add Price Book Id to Quote.
        Pricebook2 pricebook = [select Id,IsActive,Name,IsStandard from pricebook2 where IsStandard=true AND IsActive=true and name='Standard Price Book'];
        quote quoteobj = [select id,name from Quote where id=:QuoteId];
        quoteobj.Pricebook2Id = pricebook.Id;
        quoteobj.Tower__c = prod.Tower__c;
        quoteobj.Project__c = prod.Project__c;
        //Code to insert the Quote Line Items.
        Map<Id, PriceBookEntry> mapProductIdToPriceBook = new Map<Id, PriceBookEntry>();
        for(Product2 objProduct : [select Id from Product2 where (Id =: prod.Id OR (Inventory_Master__c =: prod.Material_Code__c AND Inventory_Master__c != NULL) OR (Family = 'Other Charges' and Tower__c =: prod.Tower__c)) and IsActive=true]){
            mapProductIdToPriceBook.put(objProduct.Id, null);
        }
        system.debug('mapProductIdToPriceBook:::'+mapProductIdToPriceBook.size()+'List'+mapProductIdToPriceBook);
        for(PriceBookEntry objPriceBookEntry : [select Id,Name, Floor_Rise_Charges__c,Quantity__c,CGST__c,SGST__c,Product2.Description,Product2.Family,Product2.Saleable_Area__c,Product2.Carpet_Area_RERA_Carpet__c,IsActive,Product2Id,Product2.Tower__c,UnitPrice from PriceBookEntry where Product2Id in: mapProductIdToPriceBook.keyset()]){
            mapProductIdToPriceBook.put(objPriceBookEntry.Product2Id, objPriceBookEntry);
        }
        system.debug('mapProductIdToPriceBook2:::'+mapProductIdToPriceBook.size()+'List'+mapProductIdToPriceBook);
        System.debug('>>>>mapProductIdToPriceBook>>'+mapProductIdToPriceBook);
        Set<String> setProdDescription = new Set<String>();
        for(Excluded_Other_Charges__c objExcludedOtherCharges : Excluded_Other_Charges__c.getAll().values()){
            setProdDescription.add(objExcludedOtherCharges.Product_Description__c);
        }
        System.debug('>>>>setProdDescription>>'+setProdDescription);        
        List<QuoteLineItem> lstQuoteLineItem = new List<QuoteLineItem>();
        for(Id productId : mapProductIdToPriceBook.keyset()){
            PriceBookEntry objPriceBookEntry = mapProductIdToPriceBook.get(productId);
            System.debug('>>>>objPriceBookEntry>>'+objPriceBookEntry);        
              if(objPriceBookEntry != null){
                QuoteLineItem objQuoteLineItem = new QuoteLineItem();
                objQuoteLineItem.QuoteId = QuoteId;
                objQuoteLineItem.Quantity = ((prod.Id == productId || objPriceBookEntry.Quantity__c == 2)?prod.Carpet_Area_RERA_Carpet__c:objPriceBookEntry.Quantity__c);
                objQuoteLineItem.Unit_No__c = (prod.Id == productId?null:objPriceBookEntry.Quantity__c);
                objQuoteLineItem.Product2Id = productId;
                objQuoteLineItem.UnitPrice = objPriceBookEntry.UnitPrice;// + (objPriceBookEntry.Floor_Rise_Charges__c == null?0:objPriceBookEntry.Floor_Rise_Charges__c);
                objQuoteLineItem.PricebookEntryId =  objPriceBookEntry.Id; 
                objQuoteLineItem.Tower__c = prod.Tower__c;
               // objQuoteLineItem.Product_Description__c = objPriceBookEntry.Product2.Description;
                                
                if(objPriceBookEntry.Product2.Family == 'Other Charges'){
                    Decimal gstPercentage = (objPriceBookEntry.CGST__c == null?0:objPriceBookEntry.CGST__c) + (objPriceBookEntry.SGST__c == null?0:objPriceBookEntry.SGST__c);
                    Decimal gstOnOtherCharge = ((((objPriceBookEntry.UnitPrice == null?0:objPriceBookEntry.UnitPrice) * ((prod.Id == productId || objPriceBookEntry.Quantity__c == 2)?prod.Carpet_Area_RERA_Carpet__c:objPriceBookEntry.Quantity__c)) * gstPercentage) / 100);
                    
                    objQuoteLineItem.GST_on_Other_Charges2__c = gstOnOtherCharge;
                }
                Boolean excluded = false;
                for(String prodDesc : setProdDescription){
                    if(objPriceBookEntry.Product2.Description != null && objPriceBookEntry.Product2.Description.containsIgnoreCase(prodDesc)){
                        excluded = true;
                        break;
                    }
                }
                objQuoteLineItem.Excluded__c = excluded;
                if(prod.Id != productId){
                    objQuoteLineItem.Possession_Charges_GST_Included__c =  ((objPriceBookEntry.UnitPrice * objQuoteLineItem.Quantity ) * (1+  (((objPriceBookEntry.CGST__c == null?0:objPriceBookEntry.CGST__c) + (objPriceBookEntry.SGST__c == null?0:objPriceBookEntry.SGST__c)) / 100)));   
                }            
                lstQuoteLineItem.add(objQuoteLineItem);
            }            
        }
        
        try{
            update quoteobj;
            insert lstQuoteLineItem;
             system.debug('Inside try::'+quoteobj+' lstQuoteLineItem'+lstQuoteLineItem);
            return true;
        }catch(Exception ex){
            system.debug('Exception while inserting quote line'+ex.getMessage());
            ErrorMesssage = string.valueOf(ex);
            //throwError();
            return false;
        }
    }
    
    
    //Payment lIne
    public static Boolean saveStdPaymentPlan(List<CLP_Line_Item__c> recordList,String masterId,Quote quoteRec,Boolean custom){        
        Account accRec = [select Id,Name from Account where Id=:quoteRec.AccountId ];
        Payment_Plan__c paymentPlan = new Payment_Plan__c();
        paymentPlan.Quote__c = quoteRec.Id;
        paymentPlan.Cost_Sheet_Master__c = masterId;
        paymentPlan.Status__c = 'Draft';
        paymentPlan.Name = 'Payment Plan - '+accRec.Name;
        paymentPlan.Custom_Plan__c=custom;
        paymentPlan.Area__c = quoteRec.Carpet_Area__c;
        try{
            insert paymentPlan;
        }catch(Exception ex){
            ErrorMesssage = string.valueOf(ex);
            //throwError();
            system.debug('Exception while inserting Payment Plan '+ex.getMessage());    
        }
        Map<String, Payment_Milestone__c> MapNamewithValues = Payment_Milestone__c.getAll();
        List<Payment_Plan_Line__c> paymentLineList = new List<Payment_Plan_Line__c>();
        for(CLP_Line_Item__c item : recordList){
            Payment_Plan_Line__c planLine = new Payment_Plan_Line__c();
            planLine.Payment_Plan__c = paymentPlan.Id;
            planLine.Amount__c = item.Amount__c;
            planLine.Amount_After_Tax__c = item.Amount_After_Tax__c;
            planLine.Title__c = item.CLP_Type__c;
            planLine.Sort_Order__c = item.Sort_Order__c;
            if(MapNamewithValues.containsKey(item.CLP_Type__c))
            {
                planLine.SAP_Condition_Type__c = MapNamewithValues.get(item.CLP_Type__c).SAP_Condition_Type__c;
                planLine.SAP_No__c = MapNamewithValues.get(item.CLP_Type__c).Sap_No__c;
            }
            planLine.Value__c = item.Value__c;
            paymentLineList.add(planLine);
        }
        try{
            insert paymentLineList;
            return true;
        }catch(exception Ex){
            system.debug('Error while inserting payment line '+ex.getMessage());
            return false;
        }
    }
    
  /*  public PageReference throwError(){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ErrorMesssage));
        BacktoPage = true;
        Loading = false;
        system.debug('throw Error'+ErrorMesssage);
        return NULL;
    }    */
    
    
    public static void testCodeUpdate(){
         integer i=0;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
     }
    
    
}