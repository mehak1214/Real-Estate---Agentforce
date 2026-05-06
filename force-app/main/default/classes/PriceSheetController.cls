public class PriceSheetController 
{ 
    public PriceSheetWrapper objPriceSheetWrapper{get; set;}
    private String parentId;
    public list<Payment_Plan_Line__c> lstPaymentLine{get;set;}
    public Boolean pdfMode{get; set;}
    public String paymentPlanId{get; set;}
    public List<SelectOption> lstPaymentPlanOption{get; set;}
    
    String pdfName;
    /******************************************Constructor**********************************/
    public PriceSheetController(){}
    public PriceSheetController(ApexPages.StandardController controller) {
        Quote quote = (Quote)controller.getRecord();
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
    }
    //This method is used to save the Pricesheet into the attachment under the Quote record.
    public void createPDF(){
        pdfMode = true;
        initialiseList();
        string fileName = pdfName+ ' '+'-Pricesheet.pdf';
        //Apexpages.currentPage().getHeaders().put('content-disposition', 'attachemnt; filename='+fileName);
        createAttachment(parentId, paymentPlanId, pdfName);
        System.debug('objPriceSheetWrapper >> ' +objPriceSheetWrapper);
        System.debug('objPriceSheetWrapper.objQuote >> ' +objPriceSheetWrapper.objQuote);
    }
    
    @future(callout=true)
    public static void createAttachment(String parentId, String paymentPlanId, String pdfName){
        PageReference objPageReference = new PageReference('/apex/VF_NewDisplayPriceSheet?id='+parentId+'&pdfMode=true&paymentPlanId='+paymentPlanId);
        System.debug('pdf.getParameters() >> ' +objPageReference.getParameters());
        System.debug('objPageReference >> '+objPageReference);
        Blob pdfBody = (Test.isRunningTest()?Blob.valueOf('test'):objPageReference.getContentAsPDF());
        System.debug('pdfBody >> '+pdfBody);
        String blobToString = String.valueOf(pdfBody); // pdfBody.toString();
        System.debug('blobToString >> '+blobToString);
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
    private void initialiseList(){
        List<Quote> lstQuote = new List<Quote>();
        lstQuote = [select Id, Name, GST__c, Unit_Cost_With_Discount__c, Other_Charges__c,Project__r.Name, Opportunity.Project__r.Terms_and_Conditions__c, Opportunity.Account.Name,Scanning_Charges__c,Registration__c,Agreement_Value__c,Unit_Cost__c,Agreement_Value_w_o_Tax__c,Approved_Discount__c,Stamp_Duty__c,Project_Address__c,Tower__r.Name,Carpet_Area__c , Floor_No__c, Appt__c, Other_Charges_For_GST__c,(select Id, Product2.Saleable_Area__c, Floor_Rise_Charges__c,Development_Charges__c,Preferential_Location_charges__c,UnitPrice, Quantity, Product2.EVBT__c, Product2.Different_Unit_Area__c, Product2.Description, Product2.Family, Product2.Unit_Category__c, Product2.Carpet_Area_RERA_Carpet__c, Sub_Total__c from QuoteLineItems where (Product2.Family = 'Other Charges' OR Product2.Family = 'Saleable Unit')) from Quote where Id =: parentId];
        
        if(lstQuote != null && !lstQuote.isEmpty()){
            List<QuoteLineItem> lstOtherChargesItem = new List<QuoteLineItem>();
            QuoteLineItem objSalesableUnitItem = new QuoteLineItem();
            pdfName = lstQuote[0].Name;
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
}