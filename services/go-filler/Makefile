.PHONY: bindings
bindings:
	go install github.com/ethereum/go-ethereum/cmd/abigen@v1.14.11
	cd ../../contracts && forge build
	abigen --abi ../../contracts/out/RIP7755Outbox.sol/RIP7755Outbox.abi.json --pkg bindings --type RIP7755Outbox --out bindings/rip_7755_outbox.go
