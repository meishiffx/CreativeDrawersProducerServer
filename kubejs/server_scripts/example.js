onEvent('recipes', event => {
event.recipes.custommachinery.custom_machine("custom:example", 600)
.requireItem(Item.of('minecraft:cobblestone'))
.produceEnergy(1)
})