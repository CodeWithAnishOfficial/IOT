export declare class InvoiceService {
    static generateInvoice(session: any): Promise<Buffer>;
    static sendInvoiceEmail(email: string, invoiceBuffer: Buffer, session: any): Promise<void>;
}
