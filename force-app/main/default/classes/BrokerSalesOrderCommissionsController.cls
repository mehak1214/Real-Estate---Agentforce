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
}