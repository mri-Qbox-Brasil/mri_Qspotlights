local spotlights = {}

lib.callback.register('qw_spotlights:getSpotlights', function()
    return spotlights
end)

RegisterNetEvent("qw_spotlights:server:sync", function(data)
    spotlights = data
    TriggerClientEvent("qw_spotlights:client:sync", -1, spotlights)
end)

lib.addCommand('spotlight', {
    help = 'Ativa luzes dentro do jogo',
    params = {
        {
            name = 'deletar',
            type = 'number',
            help = '1 para poder deletar',
            optional = true
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local delete = args?.delete == 1 and true or false

    if not delete then
        TriggerClientEvent('qw_spotlights:client:newSpotlight', source)
    else
        TriggerClientEvent('qw_spotlights:client:remove', source)
    end
end)