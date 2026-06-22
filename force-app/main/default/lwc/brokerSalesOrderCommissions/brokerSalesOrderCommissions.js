import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesOrderCommissions from '@salesforce/apex/BrokerSalesOrderCommissionsController.getSalesOrderCommissions';
import getInvoiceStatusForOrders from '@salesforce/apex/BrokerSalesOrderCommissionsController.getInvoiceStatusForOrders';
import createInvoice from '@salesforce/apex/BrokerSalesOrderCommissionsController.createInvoice';
import uploadInvoice from '@salesforce/apex/BrokerSalesOrderCommissionsController.uploadInvoice';
import getInvoicePdfBase64 from '@salesforce/apex/BrokerSalesOrderCommissionsController.getInvoicePdfBase64';
import CURRENCY from '@salesforce/i18n/currency';

const STATUS_TONE = {
    success: ['paid', 'approved', 'sold', 'booked'],
    warning: ['pending', 'draft'],
    danger: ['cancel', 'reject']
};

export default class BrokerSalesOrderCommissions extends NavigationMixin(LightningElement) {
    @track salesOrders = [];

    searchTerm = '';
    statusFilter = 'All';
    isLoading = true;
    errorMessage = '';
    salesOrderCount = 0;
    commissionCount = 0;
    totalCommissionAmount = 0;
    totalCommissionAmountWithVat = 0;

    // Invoice tracking
    _uploadTargetOrderId = null;

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

                // Load invoice statuses
                this.loadInvoiceStatuses();
            })
            .catch((error) => {
                this.errorMessage = this.reduceError(error);
                this.salesOrders = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadInvoiceStatuses() {
        const salesOrderIds = this.salesOrders.map((order) => order.id);
        if (salesOrderIds.length === 0) {
            return;
        }

        getInvoiceStatusForOrders({ salesOrderIds })
            .then((statusMap) => {
                this.salesOrders = this.salesOrders.map((order) => {
                    const invoiceInfo = statusMap[order.id];
                    if (invoiceInfo && invoiceInfo.hasInvoice) {
                        return {
                            ...order,
                            hasInvoice: true,
                            contentDocumentId: invoiceInfo.contentDocumentId,
                            contentVersionId: invoiceInfo.contentVersionId,
                            invoiceFileName: invoiceInfo.fileName
                        };
                    }
                    return { ...order, hasInvoice: false, contentDocumentId: null, contentVersionId: null, invoiceFileName: null };
                });
            })
            .catch((error) => {
                // Silently handle — invoice status is supplementary
                console.error('Failed to load invoice statuses:', this.reduceError(error));
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
            // Invoice state (will be updated after loadInvoiceStatuses)
            hasInvoice: false,
            contentDocumentId: null,
            contentVersionId: null,
            invoiceFileName: null,
            invoiceLoading: false,
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

    // ===== Invoice Handlers =====

    stopPropagation(event) {
        event.stopPropagation();
    }

    handleCreateInvoice(event) {
        event.stopPropagation();
        const orderId = event.currentTarget.dataset.id;

        // Set loading state for this specific order
        this.setOrderInvoiceLoading(orderId, true);

        createInvoice({ salesOrderId: orderId })
            .then((result) => {
                this.salesOrders = this.salesOrders.map((order) => {
                    if (order.id !== orderId) {
                        return order;
                    }
                    return {
                        ...order,
                        hasInvoice: true,
                        contentDocumentId: result.contentDocumentId,
                        contentVersionId: result.contentVersionId,
                        invoiceFileName: result.fileName,
                        invoiceLoading: false
                    };
                });
                this.showToast('Success', 'Invoice created and attached to the Sales Order.', 'success');
            })
            .catch((error) => {
                this.setOrderInvoiceLoading(orderId, false);
                this.showToast('Error', this.reduceError(error), 'error');
            });
    }

    previewModalOpen = false;
    previewUrl = '';    handleDownloadInvoice(event) {
        event.stopPropagation();
        const orderId = event.currentTarget.dataset.id;
        const order = this.salesOrders.find((o) => o.id === orderId);
        if (!order) return;

        const docId = order.contentDocumentId;

        if (docId) {
            // Fetch the PDF securely via Apex and force a local browser download.
            // This completely bypasses Salesforce Community URL routing errors (errorduringprocessing.jsp).
            getInvoicePdfBase64({ documentId: docId })
                .then(base64 => {
                    const binary = atob(base64);
                    const array = new Uint8Array(binary.length);
                    for (let i = 0; i < binary.length; i++) {
                        array[i] = binary.charCodeAt(i);
                    }
                    const blob = new Blob([array], { type: 'application/pdf' });
                    const blobUrl = URL.createObjectURL(blob);
                    
                    const a = document.createElement('a');
                    a.href = blobUrl;
                    a.download = order.fileName || 'Invoice.pdf';
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    
                    setTimeout(() => URL.revokeObjectURL(blobUrl), 100);
                })
                .catch(error => {
                    console.error('Error fetching PDF:', error);
                    this.showToast('Error', 'Could not download the invoice.', 'error');
                });
        } else {
            this.showToast('Error', 'No document available to download.', 'error');
        }
    }

    closePreview() {
        this.previewModalOpen = false;
        this.previewUrl = '';
    }

    handleUploadClick(event) {
        event.stopPropagation();
        const orderId = event.currentTarget.dataset.id;
        this._uploadTargetOrderId = orderId;

        // Trigger the hidden file input
        const fileInput = this.template.querySelector('.invoice-file-input');
        if (fileInput) {
            fileInput.value = null; // Reset so the same file can be re-selected
            fileInput.click();
        }
    }

    handleFileSelected(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }

        const orderId = this._uploadTargetOrderId;
        if (!orderId) {
            return;
        }

        // Validate file size (max 10MB)
        const MAX_FILE_SIZE = 10 * 1024 * 1024;
        if (file.size > MAX_FILE_SIZE) {
            this.showToast('Error', 'File size exceeds the 10MB limit.', 'error');
            return;
        }

        this.setOrderInvoiceLoading(orderId, true);

        const reader = new FileReader();
        reader.onload = () => {
            // Extract base64 data (remove the data:...;base64, prefix)
            const base64 = reader.result.split(',')[1];

            uploadInvoice({
                salesOrderId: orderId,
                fileName: file.name,
                base64Data: base64,
                contentType: file.type
            })
                .then((result) => {
                    this.salesOrders = this.salesOrders.map((order) => {
                        if (order.id !== orderId) {
                            return order;
                        }
                        return {
                            ...order,
                            hasInvoice: true,
                            contentDocumentId: result.contentDocumentId,
                            contentVersionId: result.contentVersionId,
                            invoiceFileName: result.fileName,
                            invoiceLoading: false
                        };
                    });
                    this.showToast('Success', 'Invoice uploaded and attached to the Sales Order.', 'success');
                })
                .catch((error) => {
                    this.setOrderInvoiceLoading(orderId, false);
                    this.showToast('Error', this.reduceError(error), 'error');
                });
        };
        reader.onerror = () => {
            this.setOrderInvoiceLoading(orderId, false);
            this.showToast('Error', 'Failed to read the selected file.', 'error');
        };
        reader.readAsDataURL(file);
    }

    setOrderInvoiceLoading(orderId, isLoading) {
        this.salesOrders = this.salesOrders.map((order) => {
            if (order.id !== orderId) {
                return order;
            }
            return { ...order, invoiceLoading: isLoading };
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    // ===== Utility Methods =====

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