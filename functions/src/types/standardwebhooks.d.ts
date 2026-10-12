declare module 'standardwebhooks' {
  export interface WebhookHeaders {
    'webhook-id': string;
    'webhook-timestamp': string;
    'webhook-signature': string;
    [key: string]: string | undefined;
  }

  export class Webhook {
    constructor(secret: string);
    verify(payload: string | Buffer, headers: WebhookHeaders | Record<string, string | undefined>): unknown;
    sign(msgId: string, timestamp: number | Date, payload: string | Buffer): string;
  }
}
