/**
 * InApp message data structure for callbacks.
 */
/** @public */
export interface InAppMessage {
  messageId: string;
  deliveryId?: string;
  elementId?: string;
}
