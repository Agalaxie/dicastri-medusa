import { ExecArgs } from "@medusajs/framework/types";
import {
  ContainerRegistrationKeys,
  Modules,
} from "@medusajs/framework/utils";
import {
  linkSalesChannelsToApiKeyWorkflow,
} from "@medusajs/medusa/core-flows";

export default async function fixPublishableKey({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER);
  const salesChannelModuleService = container.resolve(Modules.SALES_CHANNEL);
  const apiKeyModuleService = container.resolve(Modules.API_KEY);

  logger.info("Checking sales channels and publishable keys...");

  // Get default sales channel
  const salesChannels = await salesChannelModuleService.listSalesChannels({
    name: "Default Sales Channel",
  });

  if (!salesChannels.length) {
    logger.error("No default sales channel found!");
    return;
  }

  const salesChannel = salesChannels[0];
  logger.info(`Found sales channel: ${salesChannel.name} (${salesChannel.id})`);

  // Get all publishable API keys
  const apiKeys = await apiKeyModuleService.listApiKeys({
    type: "publishable",
  });

  if (!apiKeys.length) {
    logger.error("No publishable API keys found!");
    return;
  }

  logger.info(`Found ${apiKeys.length} publishable key(s)`);

  // Link each publishable key to the sales channel
  for (const apiKey of apiKeys) {
    logger.info(`Linking key ${apiKey.id} (${apiKey.title}) to sales channel...`);

    try {
      await linkSalesChannelsToApiKeyWorkflow(container).run({
        input: {
          id: apiKey.id,
          add: [salesChannel.id],
        },
      });
      logger.info(`✓ Successfully linked ${apiKey.title}`);
    } catch (error: any) {
      if (error.message?.includes("already exists")) {
        logger.info(`✓ ${apiKey.title} already linked to sales channel`);
      } else {
        logger.error(`Error linking ${apiKey.title}: ${error.message}`);
      }
    }
  }

  logger.info("Done!");
}
