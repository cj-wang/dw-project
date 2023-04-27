
%dw 2.0
output application/json
---
payload update {
  case .deployedApis.environmentalSummary! -> (
    keysOf(
      payload.deployedApis.details groupBy $.env
    ) map (ENV) -> do {
      var envApps = payload.deployedApis.details 
              filter $.env ~= ENV
      ---
      {
        environmentName: ENV,
        totalVcores: envApps reduce ((item, acc = 0) -> acc + item.vCore),
        totalWorkers: envApps reduce ((item, acc = 0) -> acc + item.workers),
        count: sizeOf(envApps)
      }
    }
  )
}