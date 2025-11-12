import { ExecArgs } from "@medusajs/framework/types";
import {
  ContainerRegistrationKeys,
  Modules,
} from "@medusajs/framework/utils";
import {
  createRegionsWorkflow,
  createSalesChannelsWorkflow,
  updateStoresWorkflow,
} from "@medusajs/medusa/core-flows";

export default async function fixRegions({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER);
  const salesChannelModuleService = container.resolve(Modules.SALES_CHANNEL);
  const storeModuleService = container.resolve(Modules.STORE);
  const regionModuleService = container.resolve(Modules.REGION);

  logger.info("Checking existing regions...");
  const existingRegions = await regionModuleService.listRegions();

  if (existingRegions.length > 0) {
    logger.info(`Found ${existingRegions.length} existing region(s).`);
    existingRegions.forEach(region => {
      logger.info(`- ${region.name} (${region.currency_code})`);
    });
    logger.info("Regions already exist. No action needed.");
    return;
  }

  logger.info("No regions found. Creating US region...");

  const [store] = await storeModuleService.listStores();
  let defaultSalesChannel = await salesChannelModuleService.listSalesChannels({
    name: "Default Sales Channel",
  });

  if (!defaultSalesChannel.length) {
    logger.info("Creating default sales channel...");
    const { result: salesChannelResult } = await createSalesChannelsWorkflow(
      container
    ).run({
      input: {
        salesChannelsData: [
          {
            name: "Default Sales Channel",
          },
        ],
      },
    });
    defaultSalesChannel = salesChannelResult;
  }

  await updateStoresWorkflow(container).run({
    input: {
      selector: { id: store.id },
      update: {
        default_sales_channel_id: defaultSalesChannel[0].id,
      },
    },
  });

  logger.info("Creating US region...");
  const { result: regionResult } = await createRegionsWorkflow(container).run({
    input: {
      regions: [
        {
          name: "United States",
          currency_code: "usd",
          countries: ["us"],
          payment_providers: ["pp_system_default"],
        },
      ],
    },
  });

  logger.info("Region created successfully!");
  logger.info(`Region: ${regionResult[0].name} (${regionResult[0].currency_code})`);
}
