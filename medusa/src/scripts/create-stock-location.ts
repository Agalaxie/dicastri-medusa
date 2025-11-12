import { ExecArgs } from "@medusajs/framework/types";
import {
  ContainerRegistrationKeys,
  Modules,
} from "@medusajs/framework/utils";
import {
  createStockLocationsWorkflow,
  linkSalesChannelsToStockLocationWorkflow,
  updateStoresWorkflow,
} from "@medusajs/medusa/core-flows";

export default async function createStockLocation({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER);
  const link = container.resolve(ContainerRegistrationKeys.LINK);
  const salesChannelModuleService = container.resolve(Modules.SALES_CHANNEL);
  const storeModuleService = container.resolve(Modules.STORE);

  logger.info("Creating stock location...");
  const { result: stockLocationResult } = await createStockLocationsWorkflow(
    container
  ).run({
    input: {
      locations: [
        {
          name: "Main Warehouse",
          address: {
            city: "Paris",
            country_code: "FR",
            address_1: "123 Main St",
          },
        },
      ],
    },
  });
  const stockLocation = stockLocationResult[0];
  logger.info(`✓ Stock location created: ${stockLocation.name} (${stockLocation.id})`);

  logger.info("Linking to fulfillment provider...");
  await link.create({
    [Modules.STOCK_LOCATION]: {
      stock_location_id: stockLocation.id,
    },
    [Modules.FULFILLMENT]: {
      fulfillment_provider_id: "manual_manual",
    },
  });
  logger.info("✓ Linked to manual fulfillment provider");

  logger.info("Updating store default location...");
  const [store] = await storeModuleService.listStores();
  await updateStoresWorkflow(container).run({
    input: {
      selector: { id: store.id },
      update: {
        default_location_id: stockLocation.id,
      },
    },
  });
  logger.info("✓ Store default location updated");

  logger.info("Linking to default sales channel...");
  const defaultSalesChannel = await salesChannelModuleService.listSalesChannels({
    name: "Default Sales Channel",
  });

  if (defaultSalesChannel.length) {
    await linkSalesChannelsToStockLocationWorkflow(container).run({
      input: {
        id: stockLocation.id,
        add: [defaultSalesChannel[0].id],
      },
    });
    logger.info("✓ Linked to default sales channel");
  }

  logger.info("Done! 🎉");
}
