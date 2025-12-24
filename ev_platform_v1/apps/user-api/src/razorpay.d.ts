declare module 'razorpay' {
  export interface RazorpayOptions {
    key_id: string;
    key_secret: string;
  }

  export interface Orders {
    create(params: any): Promise<any>;
  }

  export class Razorpay {
    constructor(options: RazorpayOptions);
    orders: Orders;
  }

  export default Razorpay;
}
