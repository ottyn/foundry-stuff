// Creates a hook on world load to listen for turn change in a combat encounter.
// Looks for both weapon and consumable items in actor inventory and deletes if their Qty is 0

// Wait for world to fully load
Hooks.once('ready', () => {
  Hooks.on('combatTurnChange', async (encounter) => {
    if (encounter.combatant.isOwner) {
      // Process weapons
      encounter.combatant.actor.itemTypes.weapon
        .filter((item) => item.system.temporary && item.system.quantity === 0)
        .forEach((item) => item.delete());
      // Process consumables
      encounter.combatant.actor.itemTypes.consumable
        .filter((item) => item.system.temporary && item.system.quantity === 0)
        .forEach((item) => item.delete());
    }
  });

  console.log('Quick Alchemy Fixes || Created Clear Temporary Items Hook');
});
