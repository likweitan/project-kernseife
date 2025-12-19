import { Setting } from "#cds-models/kernseife/db";
import { log } from "@sap/cds";

const LOG = log("Settings");

export const getActiveSettings = async (): Promise<Setting> => {
  const result = await SELECT.one.from('kernseife.db.Settings')
  //.columns("")
  .where({ ID: "1" });
  LOG.info("settings", result);
  return result;
}
