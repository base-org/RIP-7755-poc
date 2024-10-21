import config from "../config";

export default class ConfigService {
  private configObj: any = structuredClone(config);

  get(key: string): any {
    let val = this.configObj[key];

    if (!val) {
      val = process.env[key];
    }

    return val;
  }

  getOrThrow(key: string): any {
    let val = this.configObj[key];

    if (!val) {
      val = process.env[key];
    }

    if (!val) {
      throw new Error(`No config value for key ${key}`);
    }

    return val;
  }
}
