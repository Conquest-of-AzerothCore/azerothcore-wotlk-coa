# Recovery records preserve the disposed quantity

Partial stack deletion and vendor sales previously recorded the entire original stack in recovery_item. Recording now uses the actual requested quantity, capped at the existing stack, and zero-count whole-stack deletion keeps its original behavior. The synchronous INSERT uses DirectExecute rather than the result-query API.

This corrects future basic recovery records only. It does not reconstruct old quantities or preserve missing enchant/gem/random-property data, and it does not yet add the new native self-service recovery paths. No configuration changes or migration required. Formatting/static checks only; build and gameplay verification pending.
