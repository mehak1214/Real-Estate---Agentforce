public with sharing class BrokerPaymentPlanAction {

    public class Request {
        @InvocableVariable(
            label='Typology'
            description='Unit Typology'
            required=true
        )
        public String typology;
    }

    public class Response {

        @InvocableVariable
        public String typology;

        @InvocableVariable
        public Decimal startingPriceAED;

        @InvocableVariable
        public Decimal bookingAmountAED;

        @InvocableVariable
        public Decimal agreementChargesAED;

        @InvocableVariable
        public Decimal transferHandoverAED;

        @InvocableVariable
        public Decimal balanceAED;

        @InvocableVariable
        public Decimal monthlyInstallmentAED;

        @InvocableVariable
        public Integer installmentDurationMonths;

        @InvocableVariable
        public String paymentPlanSummary;
    }

    @InvocableMethod(
        label='Broker Payment Plan'
        description='Returns payment plan details for a selected unit typology'
    )
    public static List<Response> getPaymentPlan(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for(Request request : requests) {

            Response res = new Response();
            res.installmentDurationMonths = 60;

            switch on request.typology {

                when '1 BHK' {

                    res.typology = '1 BHK';
                    res.startingPriceAED = 950000;
                    res.bookingAmountAED = 95000;
                    res.agreementChargesAED = 38000;
                    res.transferHandoverAED = 190000;
                    res.balanceAED = 665000;
                    res.monthlyInstallmentAED = 11083;

                }

                when '2 BHK' {

                    res.typology = '2 BHK';
                    res.startingPriceAED = 1450000;
                    res.bookingAmountAED = 145000;
                    res.agreementChargesAED = 58000;
                    res.transferHandoverAED = 290000;
                    res.balanceAED = 1015000;
                    res.monthlyInstallmentAED = 16917;

                }

                when '3 BHK' {

                    res.typology = '3 BHK';
                    res.startingPriceAED = 2200000;
                    res.bookingAmountAED = 220000;
                    res.agreementChargesAED = 88000;
                    res.transferHandoverAED = 440000;
                    res.balanceAED = 1540000;
                    res.monthlyInstallmentAED = 25667;

                }

                when '4 BHK Sky Villa + Pool' {

                    res.typology = '4 BHK Sky Villa + Pool';
                    res.startingPriceAED = 4500000;
                    res.bookingAmountAED = 450000;
                    res.agreementChargesAED = 180000;
                    res.transferHandoverAED = 900000;
                    res.balanceAED = 3150000;
                    res.monthlyInstallmentAED = 52500;

                }

                when 'Plot' {

                    res.typology = 'Plot';
                    res.startingPriceAED = 1200000;
                    res.bookingAmountAED = 120000;
                    res.agreementChargesAED = 48000;
                    res.transferHandoverAED = 240000;
                    res.balanceAED = 840000;
                    res.monthlyInstallmentAED = 14000;

                }

                when else {

                    throw new AuraHandledException(
                        'Supported typologies are: 1 BHK, 2 BHK, 3 BHK, 4 BHK Sky Villa + Pool, Plot'
                    );

                }
            }

            res.paymentPlanSummary =
                'Typology: ' + res.typology +
                ', Starting Price: AED ' + res.startingPriceAED +
                ', Booking: AED ' + res.bookingAmountAED +
                ', Agreement Charges: AED ' + res.agreementChargesAED +
                ', Transfer/Handover: AED ' + res.transferHandoverAED +
                ', Balance: AED ' + res.balanceAED +
                ', Monthly Installment: AED ' + res.monthlyInstallmentAED +
                ' for ' + res.installmentDurationMonths + ' months';

            responses.add(res);
        }

        return responses;
    }
}