package main

import (
	"os"

	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/fetcher"
	"github.com/base-org/RIP-7755-poc/services/go-filler/log-fetcher/internal/flags"
	"github.com/ethereum/go-ethereum/log"
	"github.com/urfave/cli/v2"
)

func main() {
	app := &cli.App{
		Name:    "log-fetcher",
		Version: "0.0.1",
		Usage:   "Fetches logs from a given set of chains and stores them in MongoDB",
		Flags:   flags.Flags,
		Action:  fetcher.Main,
	}

	if err := app.Run(os.Args); err != nil {
		log.Crit("Failed to run app", "error", err)
	}
}
