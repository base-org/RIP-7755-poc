import { sleep } from "bun";

import type { ExponentialBackoffOptions } from "../types/utils";

// A wrapper function applying an exponential backoff algorithm to any function call to add better resiliency
export default async function exponentialBackoff(
  fn: () => Promise<any>,
  opts: ExponentialBackoffOptions = {}
): Promise<any> {
  let failures = 0;
  let success = false;
  let result: any;

  const maxBackoff = opts.maxBackoff || 64000; // 64 seconds or 2^6
  const maxAttempts = opts.maxAttempts || 60;

  while (!success && failures++ < maxAttempts) {
    try {
      result = await fn();

      success = opts.successCallback ? opts.successCallback(result) : true;

      if (!success) {
        throw new Error(`Invalid result: ${result}`);
      }
    } catch (e) {
      console.error("Exponential Backoff:", e);

      // exponential backoff - 2^failures + random milliseconds
      await sleep(
        Math.min(maxBackoff, 1000 * 2 ** failures) + Math.random() * 1000
      );
    }
  }

  if (!success) {
    console.error(`Exponential Backoff failed after ${failures - 1} attempts`);
  }

  return result;
}
