select 
    country,
    s.value:state::varchar as state,
    c.value:zipcode::varchar as zipcode,
    c.value:city::varchar as city
from raw.geo.countries
left join lateral flatten (input => states) as s
left join lateral flatten (input => s.value:zipcodes) as c