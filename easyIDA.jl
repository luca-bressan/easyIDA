###############################################################################
# easyIDA, as updated on August 30th, 2024
###############################################################################
# MIT License
#
# Copyright (c) 2024, Luca Bressan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################

using JuMP, HiGHS, DataFrames, CSV

# Importing data. See attached templates for an example of the supported format.
mktdata = CSV.read("2024080311MIA1_mktdata.csv", DataFrames.DataFrame)
grid_topology = CSV.read("2024080311MIA1_grid_topology.csv", DataFrames.DataFrame)

# Create model
model = Model(HiGHS.Optimizer)
zones = DataFrames.unique([grid_topology.SOURCE; grid_topology.DESTINATION])

# Primal problem
mktdata.ORDER_ID = [1:length(mktdata.PRICE);] # Indexing orders
@variable(model, x[i=mktdata.ORDER_ID] >= 0) # Order acceptance ratio
mktdata.x = Array(x)
@constraint(model, grid_balance_constraint1, -sum(mktdata.QTY .* x) <= 0.0) # The national grid shall be balanced i.e. consumption matches generation
@constraint(model, grid_balance_constraint2, sum(mktdata.QTY .* x) <= 0.0)
@constraint(model,
    [i in mktdata.ORDER_ID],
    x[i] <= 1) # Obvious
sinking_constraint = @constraint(model,
    [zone in zones],
    sum(mktdata.QTY[mktdata.ZONE.==zone, :] .*
    mktdata.x[mktdata.ZONE.==zone, :]) <=
    sum(grid_topology.ATC[grid_topology.DESTINATION.==zone])
) # No bidding zone shall import more energy than the sum of ATC for lines having such zone as their destination
sourcing_constraint = @constraint(model,
    [zone in zones],
    -sum(mktdata.QTY[mktdata.ZONE.==zone, :] .*
    mktdata.x[mktdata.ZONE.==zone, :]) <=
    sum(grid_topology.ATC[grid_topology.SOURCE.==zone])
) # No bidding zone shall import more energy than the sum of ATC for lines having such zone as their source

@objective(model, Max, sum((mktdata.PRICE .* mktdata.QTY .* x))) # Maximize exchanged value

# Define dual problem
@variable(model, MCP_UNC) # System unconstrained price
@variable(model, u[i=zones] >= 0) # Bidding zone cost of sourcing congestion
@variable(model, v[i=zones] >= 0) # Bidding zone cost of sinking congestion
@variable(model, s[i=mktdata.ORDER_ID] >= 0) # Order value

@constraint(model,
    [order in eachrow(mktdata)],
    s[order.ORDER_ID] >= order.QTY * (order.PRICE - MCP_UNC - u[order.ZONE] + v[order.ZONE])
) # Order value shall not be less than the value given by its quantity priced as cleared

@constraint(model,
    [zone in zones],
    -9999.0 <= MCP_UNC + u[zone] - v[zone] <= 9999.0
) # IDA price constraint

# Enforce strong duality
@constraint(model, sum((mktdata.PRICE .* mktdata.QTY .* x)) == sum(s) + sum([sum(grid_topology.ATC[grid_topology.DESTINATION.==zone]) .* u[zone] for zone in zones]) + sum([sum(grid_topology.ATC[grid_topology.SOURCE.==zone]) .* v[zone] for zone in zones]))

# Summon magical gnomes
optimize!(model)

# Compute market results TODO: add line usage and remove some ugliness
market_results = DataFrames.DataFrame()
market_results.zone = zones
market_results.unconstrained_price = ones(length(zones)) * value(MCP_UNC)
market_results.zonal_clearing_price = zeros(length(zones))
market_results.generation = zeros(length(zones))
market_results.consumption = zeros(length(zones))

for zonal_results in eachrow(market_results)
    market_results.zonal_clearing_price[market_results.zone.==zonal_results.zone] =
    market_results.unconstrained_price[market_results.zone.==zonal_results.zone] .+
    JuMP.value.(u)[zonal_results.zone] .-
    JuMP.value.(v)[zonal_results.zone]
end

for zonal_results in eachrow(market_results)
    zonal_results.generation =
    -sum(JuMP.value.(mktdata.x[mktdata.ZONE.==zonal_results.zone]) .*
        mktdata.QTY[mktdata.ZONE.==zonal_results.zone] .*
        (mktdata.PURPOSE[mktdata.ZONE.==zonal_results.zone] .== "OFF")
        )
end

for zonal_results in eachrow(market_results)
    zonal_results.consumption =
    sum(JuMP.value.(mktdata.x[mktdata.ZONE.==zonal_results.zone]) .*
        mktdata.QTY[mktdata.ZONE.==zonal_results.zone] .*
        (mktdata.PURPOSE[mktdata.ZONE.==zonal_results.zone] .== "BID")
        )
end

show(stdout, "text/plain", market_results)