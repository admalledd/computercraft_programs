

-- Not linked into the getprog system, manual install/use only


ae_net = peripheral.wrap("front")

--all_items = ae_net.getAvailableItems()

--dump(all_items)
fingerprint = {['dmg']= 0, ['id'] = 'minecraft:cobblestone'}
ae_net.exportItem(fingerprint,"EAST",16)