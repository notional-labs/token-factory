# Ensure eve is installed first.

KEY="t1"
CHAINID="token-1"
MONIKER="localtoken"
KEYALGO="secp256k1"
KEYRING="test" # export EVE_KEYRING="TEST"
LOGLEVEL="info"
TRACE="" # "--trace"

toked config keyring-backend $KEYRING
toked config chain-id $CHAINID
toked config output "json"

command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

from_scratch () {

  make install

  # remove existing daemon
  rm -rf ~/.wasmd/* 

  # if $KEY exists it should be deleted
  # decorate bright ozone fork gallery riot bus exhaust worth way bone indoor calm squirrel merry zero scheme cotton until shop any excess stage laundry
  # wasm1hj5fveer5cjtn4wd6wstzugjfdxzl0xpvsr89g
  echo "decorate bright ozone fork gallery riot bus exhaust worth way bone indoor calm squirrel merry zero scheme cotton until shop any excess stage laundry" | toked keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO --recover
  # Set moniker and chain-id for Craft
  toked init $MONIKER --chain-id $CHAINID 

  # Function updates the config based on a jq argument as a string
  update_test_genesis () {
    # update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
    cat $HOME/.wasmd/config/genesis.json | jq "$1" > $HOME/.wasmd/config/tmp_genesis.json && mv $HOME/.wasmd/config/tmp_genesis.json $HOME/.wasmd/config/genesis.json
  }

  # Set gas limit in genesis
  update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
  update_test_genesis '.app_state["gov"]["voting_params"]["voting_period"]="15s"'  
  update_test_genesis '.app_state["staking"]["params"]["bond_denom"]="utoke"'
  # update_test_genesis '.app_state["bank"]["params"]["send_enabled"]=[{"denom": "utoke","enabled": false}]'
  update_test_genesis '.app_state["staking"]["params"]["min_commission_rate"]="0.050000000000000000"'    
  
  update_test_genesis '.app_state["mint"]["params"]["mint_denom"]="utoke"'  
  update_test_genesis '.app_state["gov"]["deposit_params"]["min_deposit"]=[{"denom": "utoke","amount": "1000000"}]'
  update_test_genesis '.app_state["crisis"]["constant_fee"]={"denom": "utoke","amount": "1000"}'

  # Allocate genesis accounts
  toked add-genesis-account $KEY 10000000utoke --keyring-backend $KEYRING

  # create gentx with 1 eve
  toked gentx $KEY 1000000utoke --keyring-backend $KEYRING --chain-id $CHAINID

  # Collect genesis tx
  toked collect-gentxs

  # Run this to ensure everything worked and that the genesis file is setup correctly
  toked validate-genesis
}

from_scratch

# Opens the RPC endpoint to outside connections
sed -i '/laddr = "tcp:\/\/127.0.0.1:26657"/c\laddr = "tcp:\/\/0.0.0.0:26657"' ~/.wasmd/config/config.toml
sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["\*"\]/g' ~/.wasmd/config/config.toml
# cors_allowed_origins = []

# # Start the node (remove the --pruning=nothing flag if historical queries are not needed)
toked start --pruning=nothing  --minimum-gas-prices=0utoke #--mode validator     