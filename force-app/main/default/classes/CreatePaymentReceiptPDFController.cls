public class CreatePaymentReceiptPDFController {
    
    public PaymentReceiptWrapper objPaymentReceiptWrapper {get; set;}
    public PaymentReceiptWrapper objPaymentWrapper {get; set;}
    public Boolean pdfMode {get; set;}
    //public String pdfName{get; set;}
    public String pdfContentTest{get; set;}
    
    
    public CreatePaymentReceiptPDFController(){
        pdfMode = false;
        objPaymentWrapper = new PaymentReceiptWrapper(new Payment__c());// paymentRec);
        String pdfName = '';
        pdfContentTest = '';
        if(!pdfMode){
            pdfContentTest = 'NO PDF Content';
        }
        System.debug('ReLoad objPaymentReceiptWrapper >>' +objPaymentReceiptWrapper);
        objPaymentWrapper = objPaymentReceiptWrapper;
        System.debug('ReLoad objPaymentWrapper >>' +objPaymentWrapper);
    }
    
    
    public void createPDF(Payment__c paymentRec, String paymentName){
        CreatePaymentReceiptPDFController obj = new CreatePaymentReceiptPDFController();
        pdfMode = true;
        String pdfName = paymentName;
        string fileName = pdfName+'.pdf';
        String pdfContentTest = 'Test PDF Content';
        initialiseList(paymentRec);
        //createAttachment(paymentRec.id, fileName);
        
        
        System.debug('pdfMode >> ' +pdfMode);
        System.debug('pdfName >> ' +pdfName);
        System.debug('paymentName >> ' +paymentName);
        System.debug('fileName >> ' +fileName);
        System.debug('objPaymentReceiptWrapper >> ' +objPaymentReceiptWrapper);
        System.debug('objPaymentReceiptWrapper.objPayment >> ' +objPaymentReceiptWrapper.objPayment);
        System.debug('objPaymentReceiptWrapper.objPayment >> ' +objPaymentReceiptWrapper.objPayment.Id);
        
        
        // New Page Reference - The constructor method is executed. All values are reset.        
        PageReference objPageReference = new PageReference('/apex/CreatePaymentReceiptPDF');
        System.debug('objPageReference >> '+objPageReference);
        System.debug('pdf.getParameters() >> ' +objPageReference.getParameters());
        //Blob pdfContent = Blob.toPdf(objPageReference);
        Blob pdfBody = (Test.isRunningTest()?Blob.valueOf('test'):objPageReference.getContentAsPDF());
        System.debug('pdfBody >> '+pdfBody);
        String blobToString = String.valueOf(pdfBody); // pdfBody.toString();
        System.debug('blobToString >> '+blobToString);
        Attachment attach = new Attachment();
        attach.Body = pdfBody;
        attach.Name = pdfName;
        attach.IsPrivate = false;
        attach.ParentId = paymentRec.Id;
        
        list<Attachment> listA = new list<Attachment>([Select id, Name, ParentId from attachment where Name =:pdfName and ParentId =:paymentRec.Id]);
        if(listA.size()<=0){
            insert attach;
        }
        
    }
    
    
    @future(callout=true)
    public static void createAttachment(String parentId, String pdfName){
        
        System.debug('<<<<<<<< Future Method Start >>>>>>>>');
        System.debug('pdfName >> ' +pdfName);
        System.debug('parentId >> ' +parentId);
        System.debug('<<<<<<<< Future Method End >>>>>>>>');
        
        // New Page Reference - The constructor method is executed. All values are reset.        
        PageReference objPageReference = new PageReference('/apex/CreatePaymentReceiptPDF');
        System.debug('objPageReference >> '+objPageReference);
        System.debug('pdf.getParameters() >> ' +objPageReference.getParameters());
        //Blob pdfContent = Blob.toPdf(objPageReference);
        Blob pdfBody = (Test.isRunningTest()?Blob.valueOf('test'):objPageReference.getContentAsPDF());
        System.debug('pdfBody >> '+pdfBody);
        String blobToString = String.valueOf(pdfBody); // pdfBody.toString();
        System.debug('blobToString >> '+blobToString);
        Attachment attach = new Attachment();
        attach.Body = pdfBody;
        attach.Name = pdfName;
        attach.IsPrivate = false;
        attach.ParentId = parentId;
        
        list<Attachment> listA = new list<Attachment>([Select id, Name, parentId from attachment where Name =:pdfName and parentId =:parentId]);
        if(listA.size()<=0){
            insert attach;
        }
    }
    
    
    //Method to initialize the Wrapper instance with Payment Details. 
    public void initialiseList(Payment__c paymentRec){
        //String pdfContentTest = 'TEST PDF Content';
        objPaymentReceiptWrapper = new PaymentReceiptWrapper(paymentRec);
        
    }
    
    public class PaymentReceiptWrapper{
        public Payment__c objPayment {get;set;}
        public PaymentReceiptWrapper(Payment__c objPayment) {
            this.objPayment = objPayment;
        }
    }
    
}