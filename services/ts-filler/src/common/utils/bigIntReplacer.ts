export function replaceBigInts(_: any, v: any): any {
  if (typeof v === "bigint") {
    return v.toString();
  }
  return v;
}
