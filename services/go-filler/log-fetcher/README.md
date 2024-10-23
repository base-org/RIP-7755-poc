# Log Fetcher

## Overview

The Log Fetcher serves as the first component in our fulfiller architecture. It's main purpose is to monitor events from `RIP7755Outbox` contracts on supported chains. When it ingests an event representing a cross-chain call request, it first parses the log into an ingestible format. It then validates the request by ensuring all routing information matches pre-defined chain configs for the source / destination chains. It then validates that the reward asset / amount represents a reward that would guarantee profit if this request were accepted by the system. If the request passes validation, the log fetcher passes it along to an SQS queue for further processing.
