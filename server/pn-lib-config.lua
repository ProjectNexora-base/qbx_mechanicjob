--- PN Base: expose les réglages essentiels de cette ressource à pn-lib (panel web + /configpn en jeu).
--- Sans effet si pn-lib n'est pas installé. Les valeurs sont lues à l'usage : les changements sont appliqués en direct.
local FIELDS = {
    { source = 'config.server', key = 'authorizedIds', label = 'Citizen IDs autorisés', description = 'Liste JSON des citizenid ayant accès au garage', valueType = 'json' },
    { source = 'config.shared', key = 'cost_engine', path = 'repairCostAmount.engine.costs', label = 'Coût réparation : moteur (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_body', path = 'repairCostAmount.body.costs', label = 'Coût réparation : carrosserie (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_radiator', path = 'repairCostAmount.radiator.costs', label = 'Coût réparation : radiateur (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_axle', path = 'repairCostAmount.axle.costs', label = 'Coût réparation : essieu (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_brakes', path = 'repairCostAmount.brakes.costs', label = 'Coût réparation : freins (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_clutch', path = 'repairCostAmount.clutch.costs', label = 'Coût réparation : embrayage (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'cost_fuel', path = 'repairCostAmount.fuel.costs', label = 'Coût réparation : carburant (quantité)', valueType = 'number', min = 0, max = 1000 },
    { source = 'config.shared', key = 'item_engine', path = 'repairCostAmount.engine.item', label = 'Matériau réparation : moteur', valueType = 'string' },
    { source = 'config.shared', key = 'item_body', path = 'repairCostAmount.body.item', label = 'Matériau réparation : carrosserie', valueType = 'string' },
    { source = 'config.shared', key = 'item_radiator', path = 'repairCostAmount.radiator.item', label = 'Matériau réparation : radiateur', valueType = 'string' },
    { source = 'config.shared', key = 'item_axle', path = 'repairCostAmount.axle.item', label = 'Matériau réparation : essieu', valueType = 'string' },
    { source = 'config.shared', key = 'item_brakes', path = 'repairCostAmount.brakes.item', label = 'Matériau réparation : freins', valueType = 'string' },
    { source = 'config.shared', key = 'item_clutch', path = 'repairCostAmount.clutch.item', label = 'Matériau réparation : embrayage', valueType = 'string' },
    { source = 'config.shared', key = 'item_fuel', path = 'repairCostAmount.fuel.item', label = 'Matériau réparation : carburant', valueType = 'string' },
}

local function resolve(root, path)
    local holder, last = root, path
    for part in path:gmatch('([^%.]+)%.') do
        holder = holder[part]
        if type(holder) ~= 'table' then return nil end
    end
    return holder, path:match('([^%.]+)$') or last
end

CreateThread(function()
    if GetResourceState('pn-lib') == 'missing' then return end
    local waited = 0
    while GetResourceState('pn-lib') ~= 'started' do
        Wait(500)
        waited = waited + 500
        if waited >= 120000 then return end
    end

    local ns = GetCurrentResourceName()
    local ok, err = pcall(function()
        local schema, targets = {}, {}
        for i = 1, #FIELDS do
            local f = FIELDS[i]
            local holder, last = resolve(require(f.source), f.path or f.key)
            if holder and holder[last] ~= nil then
                targets[f.key] = { holder = holder, last = last }
                schema[#schema + 1] = {
                    key = f.key, label = f.label, description = f.description,
                    valueType = f.valueType, min = f.min, max = f.max,
                    default = holder[last],
                }
            else
                print(('[%s] réglage pn-lib ignoré (introuvable): %s.%s'):format(ns, f.source, f.key))
            end
        end

        exports['pn-lib']:RegisterConfig(ns, schema)

        for i = 1, #schema do
            local key = schema[i].key
            local t = targets[key]
            local current = exports['pn-lib']:GetConfig(ns, key)
            if current ~= nil then t.holder[t.last] = current end
            exports['pn-lib']:OnConfigChange(ns, key, function(value)
                if value ~= nil then t.holder[t.last] = value end
            end)
        end
    end)
    if not ok then
        print(('[%s] configuration pn-lib indisponible: %s'):format(ns, tostring(err)))
    end
end)
