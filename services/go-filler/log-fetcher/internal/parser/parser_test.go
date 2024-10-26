package parser

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/stretchr/testify/assert"
)

var vLog = types.Log{
	Topics: []common.Hash{
		common.HexToHash("0x123456789abcdef"),
		common.HexToHash("0xabcdef123456789"),
	},
	Data: []byte{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 140, 26, 97, 123, 219, 71, 52, 47, 156, 23, 172, 135, 80, 224, 176, 112, 195, 114, 199, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 47, 189, 207, 209, 122, 3, 70, 210, 169, 216, 159, 226, 51, 187, 173, 189, 29, 193, 76, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 74, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 180, 130, 178, 146, 135, 143, 222, 100, 105, 29, 2, 138, 34, 55, 179, 78, 145, 199, 199, 234, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 76, 139, 163, 42, 93, 172, 42, 114, 11, 179, 92, 237, 181, 29, 107, 6, 125, 16, 66, 5, 166, 238, 247, 227, 90, 190, 112, 38, 114, 150, 65, 20, 127, 121, 21, 87, 60, 126, 151, 180, 126, 250, 84, 111, 95, 110, 50, 48, 38, 59, 203, 73, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 238, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 58, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 103, 47, 182, 210, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 140, 26, 97, 123, 219, 71, 52, 47, 156, 23, 172, 135, 80, 224, 176, 112, 195, 114, 199, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
}

func TestParseLog(t *testing.T) {
	parser, err := NewParser()
	if err != nil {
		t.Fatalf("Failed to create parser: %v", err)
	}

	parsedLog, err := parser.ParseLog(vLog)

	var expectedRequestHash [32]byte = vLog.Topics[1]

	assert.NoError(t, err)
	assert.Equal(t, parsedLog.RequestHash, expectedRequestHash)
	assert.Equal(t, parsedLog.Request.Requester, common.HexToAddress("0x8C1a617BdB47342F9C17Ac8750E0b070c372C721"))
	assert.Equal(t, parsedLog.Request.Calls[0].To, common.HexToAddress("0x8C1a617BdB47342F9C17Ac8750E0b070c372C721"))
	assert.Equal(t, parsedLog.Request.Calls[0].Data, []byte{})
	assert.Equal(t, parsedLog.Request.Calls[0].Value, big.NewInt(1))
	assert.Equal(t, parsedLog.Request.ProverContract, common.HexToAddress("0x062fBdCfd17A0346D2A9d89FE233bbAdBd1DC14C"))
	assert.Equal(t, parsedLog.Request.DestinationChainId, big.NewInt(84532))
	assert.Equal(t, parsedLog.Request.InboxContract, common.HexToAddress("0xB482b292878FDe64691d028A2237B34e91c7c7ea"))
	assert.Equal(t, parsedLog.Request.L2Oracle, common.HexToAddress("0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205"))
	assert.Equal(t, parsedLog.Request.L2OracleStorageKey, [32]byte{0xa6, 0xee, 0xf7, 0xe3, 0x5a, 0xbe, 0x70, 0x26, 0x72, 0x96, 0x41, 0x14, 0x7f, 0x79, 0x15, 0x57, 0x3c, 0x7e, 0x97, 0xb4, 0x7e, 0xfa, 0x54, 0x6f, 0x5f, 0x6e, 0x32, 0x30, 0x26, 0x3b, 0xcb, 0x49})
	assert.Equal(t, parsedLog.Request.RewardAsset, common.HexToAddress("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"))
	assert.Equal(t, parsedLog.Request.RewardAmount, big.NewInt(2))
	assert.Equal(t, parsedLog.Request.FinalityDelaySeconds, big.NewInt(604800))
	assert.Equal(t, parsedLog.Request.Nonce, big.NewInt(18))
	assert.Equal(t, parsedLog.Request.Expiry, big.NewInt(1731180242))
	assert.Equal(t, parsedLog.Request.PrecheckContract, common.HexToAddress("0x0000000000000000000000000000000000000000"))
	assert.Equal(t, parsedLog.Request.PrecheckData, []byte{})
}

func TestParseLog_InvalidLog(t *testing.T) {
	parser, err := NewParser()
	if err != nil {
		t.Fatalf("Failed to create parser: %v", err)
	}

	_, err = parser.ParseLog(types.Log{})
	assert.Error(t, err)
}
