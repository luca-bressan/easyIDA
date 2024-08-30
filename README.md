# easyIDA

**easyIDA** is a Julia script designed to simulate intraday power auctions for electricity markets that operate based on the Available Transfer Capacity (ATC) model. This tool allows users to run simulations by simply supplying the required market data in a CSV file, enabling them to analyze and understand the behavior of power auctions.

## Features

- **Simulate Intraday Auctions:** Simulates the intraday power auction process based on the ATC model.
- **Easy to Use:** Users only need to provide market data in the required format to run simulations.
- **Customizable:** The script can be easily adapted to accommodate different market conditions and scenarios.

## Getting Started

### Prerequisites

To use **easyIDA**, you need to have [Julia](https://julialang.org/downloads/) installed on your system.

### Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/luca-bressan/easyIDA.git
    cd easyIDA
    ```

2. Install the required Julia packages:
    ```julia
    using Pkg
    Pkg.add("CSV")
    Pkg.add("DataFrames")
    Pkg.add("JuMP")
    Pkg.add("HiGHS")
    ```

### Usage

1. Prepare your market data file in the required format (see [mkt.csv](mkt.csv) and [grid_topology.csv](grid_topology.csv)).

2. Run the script with the market data as input:
    ```pwsh
    julia easyIDA.jl path_to_your_market_data_file path_to_your_grid_topology_file path_to_output_folder
    ```

3. The script will output the results of the simulation, including key metrics.

### Example

Here’s a basic example of how to run the script:

```pwsh
julia easyIDA.jl ./mkt.csv ./grid_topology.csv ./output
```
