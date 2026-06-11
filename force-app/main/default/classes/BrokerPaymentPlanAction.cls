public with sharing class BrokerPaymentPlanAction {

    public class Request {
        @InvocableVariable(
            label='Typology'
            description='Unit Typology'
            required=true
        )
        public String typology;

        @InvocableVariable(
            label='Plot Size Sqft'
            description='Plot size in square feet. Used only when Typology is Plot. Supported sizes: 5000, 7500, 10000.'
            required=false
        )
        public Decimal plotSizeSqft;
    }

    public class Response {

        @InvocableVariable
        public String typology;

        @InvocableVariable
        public Decimal plotSizeSqft;

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

            String typology = normalizeTypology(request.typology);

            switch on typology {

                when '1 BHK' {

                    res.typology = '1 BHK';
                    applyPaymentPlan(res, 950000);

                }

                when '2 BHK' {

                    res.typology = '2 BHK';
                    applyPaymentPlan(res, 1450000);

                }

                when '3 BHK' {

                    res.typology = '3 BHK';
                    applyPaymentPlan(res, 2200000);

                }

                when '4 BHK Sky Villa + Pool' {

                    res.typology = '4 BHK Sky Villa + Pool';
                    applyPaymentPlan(res, 4500000);

                }

                when 'Plot' {

                    Decimal plotSizeSqft = request.plotSizeSqft == null
                        ? extractPlotSizeSqft(request.typology)
                        : request.plotSizeSqft;

                    if (plotSizeSqft == null) {
                        addPlotPaymentPlan(responses, 5000);
                        addPlotPaymentPlan(responses, 7500);
                        addPlotPaymentPlan(responses, 10000);
                        continue;
                    }

                    res.typology = 'Plot';
                    applyPlotPaymentPlan(res, plotSizeSqft);

                }

                when else {

                    throw new AuraHandledException(
                        'Supported typologies are: 1 BHK, 2 BHK, 3 BHK, 4 BHK Sky Villa + Pool, Plot. Supported plot sizes are: 5000, 7500, 10000 sqft.'
                    );

                }
            }

            res.paymentPlanSummary = buildPaymentPlanSummary(res);

            responses.add(res);
        }

        return responses;
    }

    private static String normalizeTypology(String typology) {
        if (String.isBlank(typology)) {
            return '';
        }

        String normalizedTypology = typology.trim();
        String lowerTypology = normalizedTypology.toLowerCase();

        if (lowerTypology == '1 bhk' || lowerTypology == '1bhk') {
            return '1 BHK';
        }
        if (lowerTypology == '2 bhk' || lowerTypology == '2bhk') {
            return '2 BHK';
        }
        if (lowerTypology == '3 bhk' || lowerTypology == '3bhk') {
            return '3 BHK';
        }
        if (lowerTypology == '4 bhk sky villa + pool' || lowerTypology == '4bhk sky villa + pool') {
            return '4 BHK Sky Villa + Pool';
        }
        if (lowerTypology.contains('plot')) {
            return 'Plot';
        }

        return normalizedTypology;
    }

    private static void applyPlotPaymentPlan(Response res, Decimal plotSizeSqft) {
        Decimal startingPriceAED;

        if (plotSizeSqft == 5000) {
            startingPriceAED = 1200000;
        } else if (plotSizeSqft == 7500) {
            startingPriceAED = 1800000;
        } else if (plotSizeSqft == 10000) {
            startingPriceAED = 2400000;
        } else {
            throw new AuraHandledException(
                'Supported plot sizes are: 5000, 7500, 10000 sqft.'
            );
        }

        res.plotSizeSqft = plotSizeSqft;
        applyPaymentPlan(res, startingPriceAED);
    }

    private static void addPlotPaymentPlan(List<Response> responses, Decimal plotSizeSqft) {
        Response res = new Response();
        res.typology = 'Plot';
        res.installmentDurationMonths = 60;
        applyPlotPaymentPlan(res, plotSizeSqft);
        res.paymentPlanSummary = buildPaymentPlanSummary(res);
        responses.add(res);
    }

    private static Decimal extractPlotSizeSqft(String typology) {
        if (String.isBlank(typology)) {
            return null;
        }

        Pattern sizePattern = Pattern.compile('(\\d{4,5})');
        Matcher sizeMatcher = sizePattern.matcher(typology);

        if (sizeMatcher.find()) {
            return Decimal.valueOf(sizeMatcher.group(1));
        }

        return null;
    }

    private static void applyPaymentPlan(Response res, Decimal startingPriceAED) {
        res.startingPriceAED = startingPriceAED;
        res.bookingAmountAED = (startingPriceAED * 0.10).setScale(0);
        res.agreementChargesAED = (startingPriceAED * 0.04).setScale(0);
        res.transferHandoverAED = (startingPriceAED * 0.20).setScale(0);
        res.balanceAED = (startingPriceAED * 0.70).setScale(0);
        res.monthlyInstallmentAED = (res.balanceAED / res.installmentDurationMonths).setScale(0);
    }

    private static String buildPaymentPlanSummary(Response res) {
        return 'Typology: ' + res.typology +
            (res.plotSizeSqft == null ? '' : ', Plot Size: ' + res.plotSizeSqft + ' sqft') +
            ', Starting Price: AED ' + res.startingPriceAED +
            ', Booking: AED ' + res.bookingAmountAED +
            ', Agreement Charges: AED ' + res.agreementChargesAED +
            ', Transfer/Handover: AED ' + res.transferHandoverAED +
            ', Balance: AED ' + res.balanceAED +
            ', Monthly Installment: AED ' + res.monthlyInstallmentAED +
            ' for ' + res.installmentDurationMonths + ' months';
    }
}
