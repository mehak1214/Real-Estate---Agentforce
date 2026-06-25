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
        List<String> queryFields = new List<String>();
        for (String fieldName : fields.keySet()) {
            Schema.DisplayType fieldType = fields.get(fieldName).getDescribe().getType();
            if (fieldType != Schema.DisplayType.Base64 &&
                fieldType != Schema.DisplayType.Address &&
                fieldType != Schema.DisplayType.Location) {
                queryFields.add(fieldName);
            }
        }
        queryFields.sort();

        payment = Database.query(
            'SELECT ' + String.join(queryFields, ',') +
            ' FROM Unit_Payment__c WHERE Id = :paymentId LIMIT 1'
        );

        buildPaymentRows(fields);
        buildRelatedRows();
    }

    private void buildPaymentRows(Map<String, Schema.SObjectField> fields) {
        Map<String, Object> populatedFields = payment.getPopulatedFieldsAsMap();
        List<String> fieldNames = new List<String>(populatedFields.keySet());
        fieldNames.sort();

        for (String fieldName : fieldNames) {
            if (fieldName == 'Id') {
                continue;
            }

            Schema.DescribeFieldResult describe = fields.get(fieldName).getDescribe();
            Object rawValue = populatedFields.get(fieldName);
            String displayValue = formatValue(rawValue, describe.getType());
            if (!String.isBlank(displayValue)) {
                paymentRows.add(new ReceiptRow(describe.getLabel(), displayValue));
            }
        }
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
                SELECT Id, Name, Unit_Cost__c, Status__c
                FROM Unit__c
                WHERE Id = :unitId
                LIMIT 1
            ];
            addRow(bookingRows, 'Unit', unit.Name);
            addRow(bookingRows, 'Unit Status', unit.Status__c);
            addRow(bookingRows, 'Unit Cost', unit.Unit_Cost__c != null
                ? unit.Unit_Cost__c.format() : null);
        }

        addNamedRecord(bookingRows, 'Project', 'Project__c', (Id) payment.get('Project__c'));
        addNamedRecord(bookingRows, 'Record Owner', 'User', (Id) payment.get('OwnerId'));
        addNamedRecord(
            bookingRows,
            'Sales Consultant',
            'User',
            (Id) payment.get('Sales_Consultant__c')
        );

        if (opportunityId != null && unitId != null) {
            List<Booking_Unit__c> bookings = [
                SELECT Id, Name, Booking_Unit_Price__c, Booking_Unit_Status__c,
                    booking_status__c, Inventory__r.Name
                FROM Booking_Unit__c
                WHERE Opportunity__c = :opportunityId
                AND Unit__c = :unitId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!bookings.isEmpty()) {
                Booking_Unit__c booking = bookings[0];
                addRow(bookingRows, 'Booking Unit', booking.Name);
                addRow(bookingRows, 'Booking Status', booking.booking_status__c);
                addRow(bookingRows, 'Booking Unit Status', booking.Booking_Unit_Status__c);
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
