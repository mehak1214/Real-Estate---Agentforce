@isTest
public class BrokerPaymentPlanActionTest {

    @isTest
    static void testPlotReturnsAllSupportedSizesWhenSizeIsBlank() {
        BrokerPaymentPlanAction.Request req = new BrokerPaymentPlanAction.Request();
        req.typology = 'Plot';

        Test.startTest();
        List<BrokerPaymentPlanAction.Response> responses =
            BrokerPaymentPlanAction.getPaymentPlan(new List<BrokerPaymentPlanAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(3, responses.size(), 'Plot without a size should return all supported plot plans.');
        Assert.areEqual(Decimal.valueOf(5000), responses[0].plotSizeSqft, 'First plot plan should be for 5000 sqft.');
        Assert.areEqual(Decimal.valueOf(1200000), responses[0].startingPriceAED, '5000 sqft plot price should match.');
        Assert.areEqual(Decimal.valueOf(7500), responses[1].plotSizeSqft, 'Second plot plan should be for 7500 sqft.');
        Assert.areEqual(Decimal.valueOf(1800000), responses[1].startingPriceAED, '7500 sqft plot price should match.');
        Assert.areEqual(Decimal.valueOf(10000), responses[2].plotSizeSqft, 'Third plot plan should be for 10000 sqft.');
        Assert.areEqual(Decimal.valueOf(2400000), responses[2].startingPriceAED, '10000 sqft plot price should match.');
    }

    @isTest
    static void testSpecificPlotSizeReturnsMatchingPaymentPlan() {
        BrokerPaymentPlanAction.Request req = new BrokerPaymentPlanAction.Request();
        req.typology = 'Plot';
        req.plotSizeSqft = 7500;

        Test.startTest();
        List<BrokerPaymentPlanAction.Response> responses =
            BrokerPaymentPlanAction.getPaymentPlan(new List<BrokerPaymentPlanAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Specific plot size should return one payment plan.');
        Assert.areEqual('Plot', responses[0].typology, 'Typology should be Plot.');
        Assert.areEqual(Decimal.valueOf(7500), responses[0].plotSizeSqft, 'Plot size should match the request.');
        Assert.areEqual(Decimal.valueOf(1800000), responses[0].startingPriceAED, 'Starting price should match the 7500 sqft plan.');
        Assert.areEqual(Decimal.valueOf(180000), responses[0].bookingAmountAED, 'Booking amount should be 10%.');
        Assert.areEqual(Decimal.valueOf(72000), responses[0].agreementChargesAED, 'Agreement charges should be 4%.');
        Assert.areEqual(Decimal.valueOf(360000), responses[0].transferHandoverAED, 'Transfer/handover should be 20%.');
        Assert.areEqual(Decimal.valueOf(1260000), responses[0].balanceAED, 'Balance should be 70%.');
        Assert.areEqual(Decimal.valueOf(21000), responses[0].monthlyInstallmentAED, 'Monthly installment should split balance over 60 months.');
    }

    @isTest
    static void testPlotSizeCanBeParsedFromTypologyText() {
        BrokerPaymentPlanAction.Request req = new BrokerPaymentPlanAction.Request();
        req.typology = '7500 sqft Plot';

        Test.startTest();
        List<BrokerPaymentPlanAction.Response> responses =
            BrokerPaymentPlanAction.getPaymentPlan(new List<BrokerPaymentPlanAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Plot size in typology text should return one payment plan.');
        Assert.areEqual(Decimal.valueOf(7500), responses[0].plotSizeSqft, 'Plot size should be parsed from typology text.');
    }
}
