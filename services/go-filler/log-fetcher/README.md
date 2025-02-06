# Log Fetcher

## Overview

The Log Fetcher is the initial component in the RRC-7755 Fulfiller architecture. Its primary function is to monitor events emitted by `RRC7755Outbox` contracts across supported blockchain networks. Upon detecting an event that signifies a cross-chain call request, the Log Fetcher parses the log into a format suitable for further processing.

Next, it performs a validation of the request by checking that all routing information aligns with the pre-defined configurations for both the source and destination chains. Additionally, it ensures that the specified reward asset and amount are sufficient to guarantee a profit if the request is processed by the system.

If the request successfully passes all validation checks, the Log Fetcher forwards it to a MongoDB queue for subsequent processing.

## Getting Started

To run the log fetcher, see the [README](../README.md) in the `go-filler` directory.
