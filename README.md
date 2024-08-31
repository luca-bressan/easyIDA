# easyIDA

**easyIDA** is a Julia script designed to simulate intraday power auctions for electricity markets that operate based on the Available Transfer Capacity (ATC) model. This tool allows users to run simulations by simply supplying the required market data in a CSV file, enabling them to analyze and understand the behavior of power auctions.

This repo also includes sample data from the Italian IDA1 session with flowdate August 3rd, 2024. Public offer data is exclusive property of Gestore dei Mercati Energetici S.p.A. and is hereby redistributed for educational purposes only.

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

## Current limitations

### I am simulating the Italian IDAx and I get a mismatch between real consumptions/generations and line usages, why?

The Italian grid forms a cycle (SARD -> CORS -> CNOR -> CSUD -> SARD). For example, if you wanted to send energy from Florence to Naples, basic physics dictates that the most efficient route is through Latium, rather than taking a detour through Corsica, Sardinia, and then back to Latium before reaching Naples. However, since the model doesn't account for line losses, it may treat both paths as equally viable, even though one is less efficient. While this might lead to mismatches in energy flow, you can rest assured that prices are being calculated correctly. In the case of congestion, one of those paths will be blocked, eliminating flow indeterminacy, and the model results will align with real data.

### My market has specific additional constraints/products that are not being modeled, what should I do?

Fork this repo and adapt the model to your needs! The model is designed for a generic ATC-based market, serving as a foundation for further development rather than a specialized tool. Since I primarily work in the Italian market, there may be future specialization in that area (e.g., adding generalized cross-border constraints). Block orders will be implemented at a later stage, but UPP (PUN) calculation will not be included due to the upcoming TIDE reforms.