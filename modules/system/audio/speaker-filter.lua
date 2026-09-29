-- Turns the speaker filter (a smart filter on the card's sink) off while the
-- card plays through any other route: the headphone jack is the same sink.

local args = ...
args = args:parse (1)

log = Log.open_topic ("s-speaker-filter")

devices_om = ObjectManager {
  Interest {
    type = "device",
    Constraint { "device.name", "=", args ["device.name"] },
  }
}

filters_om = ObjectManager {
  Interest {
    type = "metadata",
    Constraint { "metadata.name", "=", "filters" },
  }
}

nodes_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "=", args ["filter.node.name"] },
  }
}

-- nil until the card has reported its routes.
on_speakers = nil

function apply ()
  local metadata = filters_om:lookup ()
  local node = nodes_om:lookup ()
  if metadata == nil or node == nil or on_speakers == nil then
    return
  end

  log:info ("speaker filter " .. (on_speakers and "on" or "off"))
  metadata:set (node ["bound-id"], "filter.smart.disabled",
      "Spa:String:JSON", tostring (not on_speakers))
end

function update (device)
  -- Enumerated rather than read from the cache, which can still hold the
  -- previous routes when params-changed fires (wireplumber#762).
  device:enum_params ("Route", function (routes, e)
    if e then
      log:warning ("failed to enum routes: " .. tostring (e))
      return
    end

    local found = false
    for p in routes:iterate () do
      local route = p:parse ().properties
      if route.direction == "Output" and route.name == args ["route"] then
        found = true
      end
    end

    if found ~= on_speakers then
      on_speakers = found
      apply ()
    end
  end)
end

devices_om:connect ("object-added", function (_, device)
  device:connect ("params-changed", function (d, id)
    if id == "Route" then
      update (d)
    end
  end)
  update (device)
end)

nodes_om:connect ("object-added", apply)
filters_om:connect ("object-added", apply)

devices_om:activate ()
nodes_om:activate ()
filters_om:activate ()
