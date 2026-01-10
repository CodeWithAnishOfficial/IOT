export declare class PaymentService {
    private razorpay;
    constructor();
    createOrder(amount: number, receipt: string): Promise<any>;
    verifyPayment(orderId: string, paymentId: string, signature: string): Promise<boolean>;
}
