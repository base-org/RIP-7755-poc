export type ExponentialBackoffOptions = {
  successCallback?: (res: any) => boolean;
  maxBackoff?: number;
  maxAttempts?: number;
};
