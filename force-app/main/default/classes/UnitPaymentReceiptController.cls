public without sharing class UnitPaymentReceiptController {

    public class ReceiptRow {
        public String label { get; set; }
        public String value { get; set; }

        public ReceiptRow(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public Unit_Payment__c payment { get; private set; }
    public List<ReceiptRow> paymentRows { get; private set; }
    public List<ReceiptRow> customerRows { get; private set; }
    public List<ReceiptRow> bookingRows { get; private set; }
    public String generatedOn { get; private set; }

    public UnitPaymentReceiptController() {
        paymentRows = new List<ReceiptRow>();
        customerRows = new List<ReceiptRow>();
        bookingRows = new List<ReceiptRow>();
        generatedOn = Datetime.now().format('dd MMM yyyy, hh:mm a');

        Id paymentId = ApexPages.currentPage().getParameters().get('id');
        if (paymentId == null) {
            return;
        }

        Map<String, Schema.SObjectField> fields =
            Schema.SObjectType.Unit_Payment__c.fields.getMap();
        List<String> queryFields = getReceiptFieldNames(fields);

        payment = Database.query(
            'SELECT ' + String.join(queryFields, ',') +
            ' FROM Unit_Payment__c WHERE Id = :paymentId LIMIT 1'
        );

        buildPaymentRows(fields);
        buildRelatedRows();
    }

    private void buildPaymentRows(Map<String, Schema.SObjectField> fields) {
        for (String fieldName : getReceiptFieldNames(fields)) {
            if (fieldName == 'Id' ||
                fieldName == 'Opportunity__c' ||
                fieldName == 'Unit__c' ||
                fieldName == 'Project__c' ||
                fieldName == 'Sales_Consultant__c') {
                continue;
            }

            Schema.DescribeFieldResult describe = fields.get(fieldName).getDescribe();
            Object rawValue = payment.get(fieldName);
            String displayValue = formatValue(rawValue, describe.getType());
            if (!String.isBlank(displayValue)) {
                paymentRows.add(new ReceiptRow(describe.getLabel(), displayValue));
            }
        }
    }

    private static List<String> getReceiptFieldNames(
        Map<String, Schema.SObjectField> availableFields
    ) {
        List<String> preferredFields = new List<String>{
            'Name',
            'PaymentStatus__c',
            'Payment_Mode__c',
            'Purpose__c',
            'Total_Amount__c',
            'Date_Acknowledged__c',
            'NameOnCard__c',
            'CardType__c',
            'CardLast4Digits__c',
            'CardIssuingBank__c',
            'Installments__c',
            'Authorization_Code__c',
            'ChequeNumber__c',
            'BankName__c',
            'ChequeDate__c',
            'ChequeClearanceDate__c',
            'Cheque_Status__c',
            'SenderAccountName__c',
            'BankReferenceNumber__c',
            'TransferReferenceUTR__c',
            'TransferDate__c'
        };

        List<String> receiptFields = new List<String>{ 'Id' };
        for (String fieldName : preferredFields) {
            if (availableFields.containsKey(fieldName)) {
                receiptFields.add(fieldName);
            }
        }

        for (String relationshipField : new List<String>{
            'Opportunity__c',
            'Unit__c',
            'Project__c',
            'Sales_Consultant__c'
        }) {
            if (availableFields.containsKey(relationshipField)) {
                receiptFields.add(relationshipField);
            }
        }
        return receiptFields;
    }

    private void buildRelatedRows() {
        Id opportunityId = (Id) payment.get('Opportunity__c');
        if (opportunityId != null) {
            Opportunity opportunity = [
                SELECT Id, Name, AccountId, Account.Name, Account.Phone,
                    Account.PersonEmail, Account.BillingStreet, Account.BillingCity,
                    Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                    Primary_Contact__c,
                    Primary_Contact__r.Name, Primary_Contact__r.Email,
                    Primary_Contact__r.Phone
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            addRow(bookingRows, 'Opportunity', opportunity.Name);
            addRow(customerRows, 'Customer Account', opportunity.Account != null
                ? opportunity.Account.Name : null);
            addRow(customerRows, 'Account Phone', opportunity.Account != null
                ? opportunity.Account.Phone : null);
            addRow(customerRows, 'Account Email', opportunity.Account != null
                ? opportunity.Account.PersonEmail : null);
            addRow(customerRows, 'Billing Address', opportunity.Account != null
                ? formatAddress(
                    opportunity.Account.BillingStreet,
                    opportunity.Account.BillingCity,
                    opportunity.Account.BillingState,
                    opportunity.Account.BillingPostalCode,
                    opportunity.Account.BillingCountry
                )
                : null);
            addRow(customerRows, 'Primary Contact', opportunity.Primary_Contact__r != null
                ? opportunity.Primary_Contact__r.Name : null);
            addRow(customerRows, 'Contact Email', opportunity.Primary_Contact__r != null
                ? opportunity.Primary_Contact__r.Email : null);
            addRow(customerRows, 'Contact Phone', opportunity.Primary_Contact__r != null
                ? opportunity.Primary_Contact__r.Phone : null);
        }

        Id unitId = (Id) payment.get('Unit__c');
        if (unitId != null) {
            Unit__c unit = [
                SELECT Id, Name
                FROM Unit__c
                WHERE Id = :unitId
                LIMIT 1
            ];
            addRow(bookingRows, 'Unit', unit.Name);
        }

        addNamedRecord(bookingRows, 'Project', 'Project__c', (Id) payment.get('Project__c'));
        addNamedRecord(
            bookingRows,
            'Sales Consultant',
            'User',
            (Id) payment.get('Sales_Consultant__c')
        );

        if (opportunityId != null && unitId != null) {
            List<Booking_Unit__c> bookings = [
                SELECT Id, Name, Booking_Unit_Price__c, Inventory__r.Name
                FROM Booking_Unit__c
                WHERE Opportunity__c = :opportunityId
                AND Unit__c = :unitId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!bookings.isEmpty()) {
                Booking_Unit__c booking = bookings[0];
                addRow(bookingRows, 'Booking Unit', booking.Name);
                addRow(bookingRows, 'Inventory', booking.Inventory__r != null
                    ? booking.Inventory__r.Name : null);
                addRow(bookingRows, 'Booking Unit Price', booking.Booking_Unit_Price__c != null
                    ? booking.Booking_Unit_Price__c.format() : null);
            }
        }
    }

    private static void addNamedRecord(
        List<ReceiptRow> rows,
        String label,
        String objectApiName,
        Id recordId
    ) {
        if (recordId == null) {
            return;
        }

        List<SObject> records = Database.query(
            'SELECT Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1'
        );
        if (!records.isEmpty()) {
            addRow(rows, label, String.valueOf(records[0].get('Name')));
        }
    }

    private static void addRow(List<ReceiptRow> rows, String label, String value) {
        if (!String.isBlank(value)) {
            rows.add(new ReceiptRow(label, value));
        }
    }

    private static String formatAddress(
        String street,
        String city,
        String state,
        String postalCode,
        String country
    ) {
        List<String> parts = new List<String>();
        for (String value : new List<String>{ street, city, state, postalCode, country }) {
            if (!String.isBlank(value)) {
                parts.add(value);
            }
        }
        return String.join(parts, ', ');
    }

    private static String formatValue(Object rawValue, Schema.DisplayType fieldType) {
        if (rawValue == null) {
            return null;
        }
        if (fieldType == Schema.DisplayType.Date) {
            return ((Date) rawValue).format();
        }
        if (fieldType == Schema.DisplayType.Datetime) {
            return ((Datetime) rawValue).format('dd MMM yyyy, hh:mm a');
        }
        if (fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Percent) {
            return ((Decimal) rawValue).format();
        }
        if (fieldType == Schema.DisplayType.Boolean) {
            return ((Boolean) rawValue) ? 'Yes' : 'No';
        }
        return String.valueOf(rawValue);
    }
}
