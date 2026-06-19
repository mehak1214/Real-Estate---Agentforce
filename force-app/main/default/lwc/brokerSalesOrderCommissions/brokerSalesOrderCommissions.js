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
    statusFilter = 'All';
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

    get hasVat() {
        return Number(this.totalCommissionAmountWithVat) > 0;
    }

    get refreshIconClass() {
        return this.isLoading ? 'spin' : '';
    }

    get statusOptions() {
        const labels = new Set();
        this.salesOrders.forEach((order) => labels.add(order.statusLabel));
        return ['All', ...Array.from(labels).sort()].map((label) => ({
            label: label === 'All' ? 'All statuses' : label,
            value: label,
            isSelected: label === this.statusFilter
        }));
    }

    get filteredSalesOrders() {
        const term = (this.searchTerm || '').trim().toLowerCase();
        return this.salesOrders.filter((order) => {
            const statusMatches = this.statusFilter === 'All' || order.statusLabel === this.statusFilter;
            if (!statusMatches) {
                return false;
            }
            return !term || order.searchText.includes(term);
        });
    }

    get filteredCount() {
        return this.filteredSalesOrders.length;
    }

    get skeletonRows() {
        return [{ key: 'sk-1' }, { key: 'sk-2' }, { key: 'sk-3' }, { key: 'sk-4' }, { key: 'sk-5' }];
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
        const statusLabel = order.status || 'No Status';
        const commissionTotal = commissions.reduce((sum, c) => sum + (Number(c.commissionAmountRaw) || 0), 0);
        
        const commissionHeaders = [];
        if (commissions.length > 0) {
            commissions[0].detailFields.forEach(f => {
                commissionHeaders.push({ id: f.apiName, label: f.label });
            });
        }

        return {
            ...order,
            isExpanded: false,
            rowClass: 'order-group',
            chevClass: '',
            commissionHeaders,
            orderNumber,
            statusLabel,
            statusTone: this.statusTone(statusLabel),
            projectNameDisplay: order.projectName || '\u2014',
            unitNameDisplay: order.unitName || '\u2014',
            netAmountDisplay: this.formatCurrencyString(order.netAmount),
            commissionCount: commissions.length,
            commissionTotalDisplay: this.formatCurrency(commissionTotal),
            hasCommissions: commissions.length > 0,
            detailFields: detailFields.filter((field) => 
                field.apiName !== 'Sales_Order_Number__c' 
                && !(field.label && field.label.toLowerCase().includes('booking unit'))
            ).map(field => ({
                ...field,
                isStatusField: field.label && field.label.toLowerCase().includes('status')
            })),
            commissions,
            searchText: [
                orderNumber,
                statusLabel,
                order.projectName,
                order.unitName,
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
                    && !(field.label && field.label.toLowerCase().includes('status'))
            )
        };
    }

    decorateFields(fields) {
        return (fields || []).map((field) => {
            let displayValue = field.value || '\u2014';
            if (field.value) {
                if (field.type === 'CURRENCY') {
                    displayValue = this.formatCurrency(field.value);
                } else if (field.type === 'PERCENT') {
                    displayValue = `${field.value}%`;
                } else if (field.type === 'DATE' || field.type === 'DATETIME') {
                    try {
                        const dateVal = new Date(field.value.replace(' ', 'T'));
                        if (!isNaN(dateVal.getTime())) {
                            displayValue = dateVal.toLocaleDateString(undefined, {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric'
                            });
                        }
                    } catch (e) {
                        // Fallback
                    }
                }
            }
            return { ...field, displayValue };
        });
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

    handleClearSearch() {
        this.searchTerm = '';
        const input = this.template.querySelector('.search-input');
        if (input) {
            input.value = '';
            input.focus();
        }
    }

    handleStatusFilterChange(event) {
        this.statusFilter = event.target.value;
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
                rowClass: isExpanded ? 'order-group expanded' : 'order-group',
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