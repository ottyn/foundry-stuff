if (!actor || !item) {
  return;
}

const versatileVial = await fromUuid(
  'Compendium.pf2e.equipment-srd.Item.ljT5pe8D7rudJqus'
);

const createdItem = await actor.createEmbeddedDocuments('Item', [
  versatileVial,
]);
createdItem[0].update({
  system: {
    equipped: { carryType: 'held', handsHeld: 1 },
    level: { value: actor.level },
  },
});

item.toChat();