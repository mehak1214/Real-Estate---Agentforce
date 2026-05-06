/*
** ____________________________________________________________________________________________
** Created by	:   Akash Pawar
** Created Date	:   00/11/2020 
** Company Name	: 	Stetig Consulting Pvt Ltd
** ============================================================================================
** Description	: 	Controller of pricesheet create vf page. This code for create pricesheet.
** ____________________________________________________________________________________________
*/

public class PriceSheetCreateController {
    
    public PriceSheetWrapper objPriceSheetWrapper{get; set;}
    private String parentId;
    public list<Payment_Plan_Line__c> lstPaymentLine{get;set;}
    public Boolean pdfMode{get; set;}
    public String paymentPlanId{get; set;}
    public List<Payment_Plan__c> lstPaymentPlanOption{get; set;}
    Public  String flag; 
    String pdfName;
    /******************************************Constructor**********************************/
    public PriceSheetCreateController(){}
    public void PriceSheetCreate() {
        string Qid = ApexPages.currentPage().getParameters().get('Qid');
        
          pdfMode = True;
        if(Qid != NULL && Qid != ''){
            Quote quote =  [Select Id, Name from Quote where ID =: Qid];
            // Quote quote = (Quote)controller.getRecord();
            if(quote != NULL){
                system.debug('quote'+quote);
                parentId = quote.Id;
                 pdfMode = True;
                //String pageMode = ApexPages.currentPage().getParameters().get('pdfMode');
                // paymentPlanId = ApexPages.currentPage().getParameters().get('paymentPlanId');
                pdfMode = true;
                lstPaymentPlanOption = new List<Payment_Plan__c>();
                    for(Payment_Plan__c objPaymentPlan : [select Id, Name from Payment_Plan__c where Quote__c =: parentId ORDER BY CreatedDate DESC]){
                        lstPaymentPlanOption.add(objPaymentPlan);
                         system.debug('Inside objPaymentPlan'+objPaymentPlan);
                    }
                    if(lstPaymentPlanOption != NULL && !lstPaymentPlanOption.isEmpty()){
                        paymentPlanId = lstPaymentPlanOption[0].Id;
                         system.debug('Inside lstPaymentPlanOption'+lstPaymentPlanOption);
                    }
               
                if(String.isNotBlank(paymentPlanId)){
                    system.debug('Inside paymentPlanId'+paymentPlanId);
                    //initialiseList();
                    createPDF();
                }
            }
            }
        }
    //This method is used to save the Pricesheet into the attachment under the Quote record.
    public void createPDF(){
        pdfMode = true;
        initialiseList();
        string fileName = pdfName+ ' '+'-Pricesheet.pdf';
        //Apexpages.currentPage().getHeaders().put('content-disposition', 'attachemnt; filename='+fileName);
        if(ApexPages.currentPage().getParameters().get('flag') != 'true'){
        createAttachment(parentId, paymentPlanId, pdfName, fileName);
        }
    }
    
    public void createAttachment(String parentId, String paymentPlanId, String pdfName, string fileName){
      flag =  ApexPages.currentPage().getParameters().get('flag');
        system.debug('flag'+flag);
        if(flag == 'false' || flag == NULL){
             system.debug('Inside'+flag);
            flag = 'true';
        PageReference objPageReference = new PageReference('/apex/PriceSheetCreate?Qid='+parentId+'&pdfMode=true&paymentPlanId='+paymentPlanId+'&flag='+flag);
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
              system.debug('Insode listA'+listA);
        if(listA.size()<=0){
            insert attach;
            system.debug('Insode Attach'+attach);
            //Apexpages.currentPage().getHeaders().put('content-disposition', 'attachemnt; filename='+fileName);
        }  
        }
    }
    
    //Method to initialize the Wrapper instance with and Quote Line Items. 
    private void initialiseList(){
        List<Quote> lstQuote = new List<Quote>();
        lstQuote = [select Id, Name, GST__c, Unit_Cost_With_Discount__c, Other_Charges__c,Project__r.Name, Opportunity.Project__r.Terms_and_Conditions__c, Opportunity.Account.Name,Scanning_Charges__c,Registration__c,Agreement_Value__c,Unit_Cost__c,Agreement_Value_w_o_Tax__c,Approved_Discount__c,Stamp_Duty__c,Project_Address__c,Tower__r.Name,Carpet_Area__c , Floor_No__c, Appt__c, Other_Charges_For_GST__c,TotalPrice,
                    (select Id, Product2.Saleable_Area__c, Floor_Rise_Charges__c,Development_Charges__c,TotalPrice ,Preferential_Location_charges__c,UnitPrice, Quantity, Product2.EVBT__c, Product2.Different_Unit_Area__c, Product2.Description, Product2.Family, Product2.Unit_Category__c, Product2.Carpet_Area_RERA_Carpet__c, Sub_Total__c from QuoteLineItems where (Product2.Family = 'Other Charges' OR Product2.Family = 'Saleable Unit' )) 
                    from Quote where Id =: parentId];
        system.debug('Inside initialiseList'+parentId+' :: lstQuote ::'+ lstQuote);
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
            System.debug('Inside ');
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
    
}