import { LightningElement, track } from 'lwc';
import getSalesOrderCommissions from '@salesforce/apex/BrokerSalesOrderCommissionsController.getSalesOrderCommissions';
import CURRENCY from '@salesforce/i18n/currency';

const STATUS_TONE = {
    success: ['paid', 'approved', 'sold', 'booked'],
    warning: ['pending', 'draft'],
    danger: ['cancel', 'reject']
};

export default class BrokerSalesOrderCommissions extends LightningElement {
    @track salesOrders = [];

    searchTerm = '';
    isLoading = true;
    errorMessage = '';
    salesOrderCount = 0;
    commissionCount = 0;
    totalCommissionAmount = 0;
    totalCommissionAmountWithVat = 0;

    connectedCallback() {
        this.loadData();
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hasOrders() {
        return this.filteredSalesOrders.length > 0;
    }

    get formattedCommissionTotal() {
        return this.formatCurrency(this.totalCommissionAmount);
    }

    get formattedCommissionWithVat() {
        return this.formatCurrency(this.totalCommissionAmountWithVat);
    }

    get filteredSalesOrders() {
        const term = (this.searchTerm || '').trim().toLowerCase();
        if (!term) {
            return this.salesOrders;
        }
        return this.salesOrders.filter((order) => order.searchText.includes(term));
    }

    loadData() {
        this.isLoading = true;
        this.errorMessage = '';

        getSalesOrderCommissions()
            .then((data) => {
                this.salesOrderCount = data.salesOrderCount || 0;
                this.commissionCount = data.commissionCount || 0;
                this.totalCommissionAmount = data.totalCommissionAmount || 0;
                this.totalCommissionAmountWithVat = data.totalCommissionAmountWithVat || 0;
                this.salesOrders = (data.salesOrders || []).map((order) => this.decorateOrder(order));
            })
            .catch((error) => {
                this.errorMessage = this.reduceError(error);
                this.salesOrders = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    decorateOrder(order) {
        const commissions = (order.commissions || []).map((commission) => this.decorateCommission(commission));
        const detailFields = this.decorateFields(order.fields);
        const orderNumberField = detailFields.find((field) => field.apiName === 'Sales_Order_Number__c');
        const orderNumber = orderNumberField && orderNumberField.value ? orderNumberField.value : order.name;
        const projectUnitLabel = [order.projectName, order.unitName].filter(Boolean).join(' \u00b7 ') || 'No project or unit linked';
        const statusLabel = order.status || 'No Status';
        const commissionTotal = commissions.reduce((sum, c) => sum + (Number(c.commissionAmountRaw) || 0), 0);

        return {
            ...order,
            isExpanded: false,
            chevClass: '',
            orderNumber,
            statusLabel,
            statusTone: this.statusTone(statusLabel),
            projectUnitLabel,
            netAmountDisplay: this.formatCurrencyString(order.netAmount),
            commissionCount: commissions.length,
            commissionTotalDisplay: this.formatCurrency(commissionTotal),
            hasCommissions: commissions.length > 0,
            detailFields: detailFields.filter((field) => field.apiName !== 'Sales_Order_Number__c'),
            commissions,
            searchText: [
                orderNumber,
                statusLabel,
                projectUnitLabel,
                order.netAmount,
                ...detailFields.map((field) => field.value),
                ...commissions.flatMap((commission) => commission.detailFields.map((field) => field.value))
            ].filter(Boolean).join(' ').toLowerCase()
        };
    }

    decorateCommission(commission) {
        const detailFields = this.decorateFields(commission.fields);
        const amountField = detailFields.find((field) => field.apiName === 'Commission_Amount__c');
        const brokerField = detailFields.find((field) => field.apiName === 'Broker__c');
        const unitField = detailFields.find((field) => field.apiName === 'Unit__c');
        const statusLabel = commission.status || 'No Status';

        return {
            ...commission,
            statusLabel,
            statusTone: this.statusTone(statusLabel),
            brokerName: brokerField ? brokerField.value : '',
            unitName: unitField ? unitField.value : '',
            commissionAmountRaw: amountField ? amountField.value : 0,
            commissionAmountDisplay: amountField ? this.formatCurrencyString(amountField.value) : '-',
            detailFields: detailFields.filter(
                (field) => field.apiName !== 'Commission_Amount__c'
                    && field.apiName !== 'Broker__c'
                    && field.apiName !== 'Unit__c'
            )
        };
    }

    decorateFields(fields) {
        return (fields || []).map((field) => ({
            ...field,
            displayValue: field.value || '\u2014'
        }));
    }

    statusTone(status) {
        const value = (status || '').toLowerCase();
        for (const tone of Object.keys(STATUS_TONE)) {
            if (STATUS_TONE[tone].some((keyword) => value.includes(keyword))) {
                return tone;
            }
        }
        return 'neutral';
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleRefresh() {
        this.loadData();
    }

    toggleOrder(event) {
        const orderId = event.currentTarget.dataset.id;
        this.salesOrders = this.salesOrders.map((order) => {
            if (order.id !== orderId) {
                return order;
            }
            const isExpanded = !order.isExpanded;
            return {
                ...order,
                isExpanded,
                chevClass: isExpanded ? 'expanded' : ''
            };
        });
    }

    formatCurrencyString(value) {
        if (value === null || value === undefined || value === '') {
            return '\u2014';
        }
        return this.formatCurrency(value);
    }

    formatCurrency(value) {
        const numericValue = Number(value);
        if (Number.isNaN(numericValue)) {
            return '\u2014';
        }
        return new Intl.NumberFormat(undefined, {
            style: 'currency',
            currency: CURRENCY,
            minimumFractionDigits: 0,
            maximumFractionDigits: 2
        }).format(numericValue);
    }

    reduceError(error) {
        if (!error) {
            return 'Something went wrong.';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        return error.message || error.statusText || 'Something went wrong.';
    }
}