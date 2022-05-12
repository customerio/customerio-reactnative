declare enum Region {
    US = "US",
    EU = "EU"
}
export declare function multiply(a: number, b: number): Promise<number>;
declare class CustomerIO {
    static initialize(siteId: string, apiKey: string, region: Region | undefined): Promise<boolean>;
    static testMethod(): Promise<string>;
}
export { CustomerIO, Region };
