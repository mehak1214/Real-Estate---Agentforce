public with sharing class BrokerSalesOrderCommissionsController {
    private static final Integer MAX_SALES_ORDERS = 200;
    private static final Integer MAX_COMMISSIONS = 500;

    // Only these fields are shown for a Sales Order, in this order.
    // (Order Number / Name and Opportunity are intentionally excluded.)
    private static final List<String> SALES_ORDER_FIELDS = new List<String>{
        'Sales_Order_Number__c',   // Sales Order Number
        'Unit__c',               // Unit (lookup, resolved via Unit__r.Name)
        'NetAmount__c',          // Net Amount
        'Status__c',             // Status
        'Project__c',            // Project (lookup, resolved via Project__r.Name)
        'Booking_Unit__c'         // Booking Unit (lookup, resolved via Booking_Unit__r.Name)
    };

    // Only these fields are shown for a Broker Commission, in this order.
    private static final List<String> COMMISSION_FIELDS = new List<String>{
        'Unit__c',               // Unit (lookup)
        'Broker__c',             // Broker (lookup)
        'Status__c',             // Status
        'Due_Date__c',            // Due Date
        'Unit_Cost__c',           // Unit Cost
        'Commission_Percent__c',  // Commission Percent
        'Commission_Amount__c'    // Commission Amount
    };

    public class DashboardDTO {
        @AuraEnabled public List<RecordDTO> salesOrders;
        @AuraEnabled public Integer salesOrderCount;
        @AuraEnabled public Integer commissionCount;
        @AuraEnabled public Decimal totalCommissionAmount;
        @AuraEnabled public Decimal totalCommissionAmountWithVat;
        @AuraEnabled public Boolean brokerFiltered;
    }

    public class RecordDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String status;
        @AuraEnabled public String projectName;
        @AuraEnabled public String unitName;
        @AuraEnabled public String netAmount;
        @AuraEnabled public List<FieldValueDTO> fields;
        @AuraEnabled public List<RecordDTO> commissions;
    }

    public class FieldValueDTO {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean hasValue;
    }

    // Not cacheable: the component's Refresh button calls this imperatively and
    // expects a live read each time. A cacheable method with no parameters would
    // return the same cached payload on every subsequent click.
    @AuraEnabled
    public static DashboardDTO getSalesOrderCommissions() {
        Map<String, Schema.SObjectField> salesOrderFieldMap = SalesOrder__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> commissionFieldMap = BrokerCommission__c.SObjectType.getDescribe().fields.getMap();

        List<String> salesOrderFieldNames = getAccessibleWhitelistedFields(salesOrderFieldMap, SALES_ORDER_FIELDS);
        List<String> commissionFieldNames = getAccessibleWhitelistedFields(commissionFieldMap, COMMISSION_FIELDS);

        User currentUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Boolean brokerFiltered = currentUser.ContactId != null;
        List<SalesOrder__c> salesOrders;
        List<BrokerCommission__c> commissions;

        if (brokerFiltered) {
            commissions = queryBrokerCommissionsForContact(commissionFieldNames, currentUser.ContactId);
            Set<Id> salesOrderIds = new Set<Id>();
            for (BrokerCommission__c commission : commissions) {
                Id salesOrderId = (Id) safeGet(commission, 'SalesOrder__c');
                if (salesOrderId != null) {
                    salesOrderIds.add(salesOrderId);
                }
            }
            salesOrders = salesOrderIds.isEmpty()
                ? new List<SalesOrder__c>()
                : querySalesOrdersByIds(salesOrderFieldNames, salesOrderIds);
        } else {
            salesOrders = queryRecentSalesOrders(salesOrderFieldNames);
            Set<Id> salesOrderIds = new Map<Id, SalesOrder__c>(salesOrders).keySet();
            commissions = salesOrderIds.isEmpty()
                ? new List<BrokerCommission__c>()
                : queryCommissionsBySalesOrderIds(commissionFieldNames, salesOrderIds);
        }

        Map<Id, List<RecordDTO>> commissionsBySalesOrderId = new Map<Id, List<RecordDTO>>();
        Decimal totalCommissionAmount = 0;
        Decimal totalCommissionAmountWithVat = 0;

        for (BrokerCommission__c commission : commissions) {
            RecordDTO commissionDTO = buildCommissionDTO(commission, commissionFieldMap, commissionFieldNames);
            Id salesOrderId = (Id) safeGet(commission, 'SalesOrder__c');
            if (salesOrderId != null) {
                if (!commissionsBySalesOrderId.containsKey(salesOrderId)) {
                    commissionsBySalesOrderId.put(salesOrderId, new List<RecordDTO>());
                }
                commissionsBySalesOrderId.get(salesOrderId).add(commissionDTO);
            }

            totalCommissionAmount += getDecimalValue(commission, 'Commission_Amount__c');
            totalCommissionAmountWithVat += getDecimalValue(commission, 'TotalCommissionAmountWithVAT__c');
        }

        List<RecordDTO> salesOrderDTOs = new List<RecordDTO>();
        for (SalesOrder__c salesOrder : salesOrders) {
            RecordDTO salesOrderDTO = buildSalesOrderDTO(salesOrder, salesOrderFieldMap, salesOrderFieldNames);
            salesOrderDTO.commissions = commissionsBySalesOrderId.containsKey(salesOrder.Id)
                ? commissionsBySalesOrderId.get(salesOrder.Id)
                : new List<RecordDTO>();
            salesOrderDTOs.add(salesOrderDTO);
        }

        DashboardDTO dashboard = new DashboardDTO();
        dashboard.salesOrders = salesOrderDTOs;
        dashboard.salesOrderCount = salesOrderDTOs.size();
        dashboard.commissionCount = commissions.size();
        dashboard.totalCommissionAmount = totalCommissionAmount;
        dashboard.totalCommissionAmountWithVat = totalCommissionAmountWithVat;
        dashboard.brokerFiltered = brokerFiltered;
        return dashboard;
    }

    private static List<SalesOrder__c> queryRecentSalesOrders(List<String> fieldNames) {
        String query = 'SELECT ' + String.join(addSalesOrderQueryFields(fieldNames), ',') +
            ' FROM SalesOrder__c ORDER BY CreatedDate DESC LIMIT ' + MAX_SALES_ORDERS;
        return Database.query(query);
    }

    private static List<SalesOrder__c> querySalesOrdersByIds(List<String> fieldNames, Set<Id> salesOrderIds) {
        String query = 'SELECT ' + String.join(addSalesOrderQueryFields(fieldNames), ',') +
            ' FROM SalesOrder__c WHERE Id IN :salesOrderIds ORDER BY CreatedDate DESC LIMIT ' + MAX_SALES_ORDERS;
        return Database.query(query);
    }

    private static List<BrokerCommission__c> queryBrokerCommissionsForContact(List<String> fieldNames, Id contactId) {
        String query = 'SELECT ' + String.join(addCommissionQueryFields(fieldNames), ',') +
            ' FROM BrokerCommission__c WHERE Broker__c = :contactId ORDER BY CreatedDate DESC LIMIT ' + MAX_COMMISSIONS;
        return Database.query(query);
    }

    private static List<BrokerCommission__c> queryCommissionsBySalesOrderIds(List<String> fieldNames, Set<Id> salesOrderIds) {
        String query = 'SELECT ' + String.join(addCommissionQueryFields(fieldNames), ',') +
            ' FROM BrokerCommission__c WHERE SalesOrder__c IN :salesOrderIds ORDER BY CreatedDate DESC LIMIT ' + MAX_COMMISSIONS;
        return Database.query(query);
    }

    /**
     * Filters the requested field whitelist down to fields that exist on the object
     * and are accessible to the running user.
     */
    private static List<String> getAccessibleWhitelistedFields(Map<String, Schema.SObjectField> fieldMap, List<String> requestedFields) {
        List<String> accessibleFields = new List<String>();
        for (String fieldName : requestedFields) {
            Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
            if (field == null) {
                continue;
            }
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (!fieldDescribe.isAccessible()) {
                continue;
            }
            accessibleFields.add(fieldName);
        }
        return accessibleFields;
    }

    private static List<String> addSalesOrderQueryFields(List<String> fieldNames) {
        List<String> queryFields = new List<String>();
        for (String fieldName : fieldNames) {
            queryFields.add(toQueryField(fieldName));
        }
        addIfMissing(queryFields, 'Status__c');
        addIfMissing(queryFields, 'NetAmount__c');
        return queryFields;
    }

    private static List<String> addCommissionQueryFields(List<String> fieldNames) {
        List<String> queryFields = new List<String>();
        for (String fieldName : fieldNames) {
            queryFields.add(toQueryField(fieldName));
        }
        addIfMissing(queryFields, 'SalesOrder__c');
        addIfMissing(queryFields, 'Broker__c');
        addIfMissing(queryFields, 'Commission_Amount__c');
        addIfMissing(queryFields, 'TotalCommissionAmountWithVAT__c');
        return queryFields;
    }

    /**
     * Converts a lookup field's API name (e.g. "Project__c") into the related
     * record's name path (e.g. "Project__r.Name") so we can display the name
     * instead of the raw Id. Non-lookup fields pass through unchanged.
     */
    private static String toQueryField(String fieldName) {
        if (isLookupField(fieldName)) {
            String relationshipName = fieldName.substring(0, fieldName.length() - 1) + 'r';
            return relationshipName + '.Name';
        }
        return fieldName;
    }

    private static Boolean isLookupField(String fieldName) {
        Set<String> lookupFields = new Set<String>{
            'opportunity__c', 'unit__c', 'project__c', 'booking_unit__c', 'broker__c'
        };
        return fieldName != null && lookupFields.contains(fieldName.toLowerCase());
    }

    private static void addIfMissing(List<String> fieldNames, String fieldName) {
        if (!containsFieldIgnoreCase(fieldNames, fieldName)) {
            fieldNames.add(fieldName);
        }
    }

    private static Boolean containsFieldIgnoreCase(List<String> fieldNames, String fieldName) {
        for (String selectedField : fieldNames) {
            if (selectedField != null && selectedField.equalsIgnoreCase(fieldName)) {
                return true;
            }
        }
        return false;
    }

    private static RecordDTO buildSalesOrderDTO(SObject record, Map<String, Schema.SObjectField> fieldMap, List<String> fieldNames) {
        RecordDTO recordDTO = baseRecordDTO(record);
        recordDTO.status = getStringValue(record, 'Status__c');
        recordDTO.projectName = getRelatedName(record, 'Project__r');
        recordDTO.unitName = getRelatedName(record, 'Unit__r');
        recordDTO.netAmount = formatValue(safeGet(record, 'NetAmount__c'));
        recordDTO.fields = buildFieldValues(record, fieldMap, fieldNames);
        return recordDTO;
    }

    private static RecordDTO buildCommissionDTO(SObject record, Map<String, Schema.SObjectField> fieldMap, List<String> fieldNames) {
        RecordDTO recordDTO = baseRecordDTO(record);
        recordDTO.status = getStringValue(record, 'Status__c');
        recordDTO.fields = buildFieldValues(record, fieldMap, fieldNames);
        return recordDTO;
    }

    private static RecordDTO baseRecordDTO(SObject record) {
        RecordDTO recordDTO = new RecordDTO();
        recordDTO.id = (Id) record.get('Id');
        recordDTO.name = getStringValue(record, 'Name');
        recordDTO.recordUrl = '/' + String.valueOf(recordDTO.id);
        return recordDTO;
    }

    private static List<FieldValueDTO> buildFieldValues(SObject record, Map<String, Schema.SObjectField> fieldMap, List<String> fieldNames) {
        List<FieldValueDTO> values = new List<FieldValueDTO>();
        for (String fieldName : fieldNames) {
            Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            String value;
            if (isLookupField(fieldName)) {
                String relationshipName = fieldName.substring(0, fieldName.length() - 1) + 'r';
                value = getRelatedName(record, relationshipName);
            } else {
                value = formatValue(safeGet(record, fieldName));
            }

            FieldValueDTO fieldValue = new FieldValueDTO();
            fieldValue.apiName = fieldName;
            fieldValue.label = fieldDescribe.getLabel();
            fieldValue.type = String.valueOf(fieldDescribe.getType());
            fieldValue.value = value;
            fieldValue.hasValue = String.isNotBlank(value);
            values.add(fieldValue);
        }
        return values;
    }

    private static String formatValue(Object value) {
        if (value == null) {
            return '';
        }
        return String.valueOf(value);
    }

    private static String getStringValue(SObject record, String fieldName) {
        Object value = safeGet(record, fieldName);
        return value == null ? null : String.valueOf(value);
    }

    private static Decimal getDecimalValue(SObject record, String fieldName) {
        Object value = safeGet(record, fieldName);
        if (value == null) {
            return 0;
        }
        try {
            return (Decimal) value;
        } catch (Exception e) {
            return 0;
        }
    }

    private static Object safeGet(SObject record, String fieldName) {
        try {
            return record.get(fieldName);
        } catch (Exception e) {
            return null;
        }
    }

    private static String getRelatedName(SObject record, String relationshipName) {
        try {
            SObject relatedRecord = record.getSObject(relationshipName);
            if (relatedRecord == null) {
                return null;
            }
            Object nameValue = relatedRecord.get('Name');
            return nameValue == null ? null : String.valueOf(nameValue);
        } catch (Exception e) {
            return null;
        }
    }

    // ===== Invoice Functionality =====

    public class InvoiceInfoDTO {
        @AuraEnabled public Boolean hasInvoice;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String fileName;
    }

    /**
     * Check which Sales Orders already have an invoice attached.
     * Looks for ContentDocumentLinks where the document title starts with 'Commission_Invoice_'.
     */
    @AuraEnabled
    public static Map<Id, InvoiceInfoDTO> getInvoiceStatusForOrders(List<Id> salesOrderIds) {
        Map<Id, InvoiceInfoDTO> result = new Map<Id, InvoiceInfoDTO>();

        if (salesOrderIds == null || salesOrderIds.isEmpty()) {
            return result;
        }

        for (Id soId : salesOrderIds) {
            InvoiceInfoDTO info = new InvoiceInfoDTO();
            info.hasInvoice = false;
            result.put(soId, info);
        }

        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId, ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :salesOrderIds
            AND ContentDocument.Title LIKE 'Commission_Invoice_%'
            ORDER BY ContentDocument.CreatedDate DESC
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }

        Map<Id, Id> docToVersionMap = new Map<Id, Id>();
        if (!docIds.isEmpty()) {
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :docIds AND IsLatest = true]) {
                docToVersionMap.put(cv.ContentDocumentId, cv.Id);
            }
        }

        for (ContentDocumentLink link : links) {
            Id entityId = link.LinkedEntityId;
            if (result.containsKey(entityId) && !result.get(entityId).hasInvoice) {
                InvoiceInfoDTO info = new InvoiceInfoDTO();
                info.hasInvoice = true;
                info.contentDocumentId = link.ContentDocumentId;
                
                Id cvId = link.ContentDocument.LatestPublishedVersionId;
                if (cvId == null) {
                    cvId = docToVersionMap.get(link.ContentDocumentId);
                }
                info.contentVersionId = cvId;
                info.fileName = link.ContentDocument.Title;
                result.put(entityId, info);
            }
        }

        return result;
    }

    /**
     * Generate an invoice PDF for a Sales Order and attach it as a ContentDocument.
     */
    @AuraEnabled
    public static InvoiceInfoDTO createInvoice(Id salesOrderId) {
        try {
            // Get the Sales Order name for the file title
            SalesOrder__c so = [
                SELECT Id, Name, Sales_Order_Number__c
                FROM SalesOrder__c
                WHERE Id = :salesOrderId
                LIMIT 1
            ];

            String orderNumber = so.Sales_Order_Number__c != null ? so.Sales_Order_Number__c : so.Name;
            String sanitizedOrderNumber = orderNumber.replaceAll('[^a-zA-Z0-9_\\-]', '_');
            String fileName = 'Commission_Invoice_' + sanitizedOrderNumber;

            // Generate PDF from VF page
            PageReference pdfPage = Page.CommissionInvoicePDFGenerator;
            pdfPage.getParameters().put('salesOrderId', salesOrderId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Create ContentVersion (which auto-creates ContentDocument)
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName + '.pdf';
            cv.VersionData = pdfBlob;
            cv.Origin = 'C'; // Content origin
            insert cv;

            // Get the auto-created ContentDocumentId
            ContentVersion insertedCv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];

            // Link the document to the Sales Order
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = insertedCv.ContentDocumentId;
            cdl.LinkedEntityId = salesOrderId;
            cdl.ShareType = 'V'; // Viewer permission
            cdl.Visibility = 'AllUsers';
            insert cdl;

            // Return result
            InvoiceInfoDTO info = new InvoiceInfoDTO();
            info.hasInvoice = true;
            info.contentDocumentId = insertedCv.ContentDocumentId;
            info.contentVersionId = cv.Id;
            info.fileName = fileName;
            return info;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to create invoice: ' + e.getMessage());
        }
    }

    /**
     * Upload a user-provided invoice file and attach it to a Sales Order.
     */
    @AuraEnabled
    public static InvoiceInfoDTO uploadInvoice(Id salesOrderId, String fileName, String base64Data, String contentType) {
        try {
            // Get the Sales Order name for the file title prefix
            SalesOrder__c so = [
                SELECT Id, Name, Sales_Order_Number__c
                FROM SalesOrder__c
                WHERE Id = :salesOrderId
                LIMIT 1
            ];

            String orderNumber = so.Sales_Order_Number__c != null ? so.Sales_Order_Number__c : so.Name;
            String sanitizedOrderNumber = orderNumber.replaceAll('[^a-zA-Z0-9_\\-]', '_');
            String docTitle = 'Commission_Invoice_' + sanitizedOrderNumber;

            // Decode and create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = docTitle;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Origin = 'C';
            insert cv;

            // Get the auto-created ContentDocumentId
            ContentVersion insertedCv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];

            // Link the document to the Sales Order
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = insertedCv.ContentDocumentId;
            cdl.LinkedEntityId = salesOrderId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            // Return result
            InvoiceInfoDTO info = new InvoiceInfoDTO();
            info.hasInvoice = true;
            info.contentDocumentId = insertedCv.ContentDocumentId;
            info.contentVersionId = cv.Id;
            info.fileName = docTitle;
            return info;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to upload invoice: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getInvoicePdfBase64(Id documentId) {
        try {
            ContentVersion cv = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId AND IsLatest = true 
                LIMIT 1
            ];
            return EncodingUtil.base64Encode(cv.VersionData);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching PDF: ' + e.getMessage());
        }
    }
}