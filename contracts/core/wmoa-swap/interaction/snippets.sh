ALICE="~/dharitri-sdk/testwallets/latest/users/alice.pem"
BOB="~/dharitri-sdk/testwallets/latest/users/bob.pem"
ADDRESS=$(drtpy data load --key=address-testnet-moa-dcdt-swap)
DEPLOY_TRANSACTION=$(drtpy data load --key=deployTransaction-testnet)
PROXY=https://testnet-gateway.dharitri.com
CHAIN_ID=T

DCDT_SYSTEM_SC_ADDRESS=drt1qqqqqqqqqqqqqqqpqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzllls6prdez

deploy() {
    ######################################################################
    ############################ Update after issue ######################
    ######################################################################
    local WRAPPED_MOA_TOKEN_ID=0x

    drtpy --verbose contract deploy --project=${PROJECT} --recall-nonce --pem=${ALICE} \
    --gas-limit=100000000 \
    --arguments ${WRAPPED_MOA_TOKEN_ID} \
    --send --outfile="deploy-testnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(drtpy data parse --file="deploy-testnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(drtpy data parse --file="deploy-testnet.interaction.json" --expression="data['contractAddress']")

    drtpy data store --key=address-testnet --value=${ADDRESS}
    drtpy data store --key=deployTransaction-testnet-moa-dcdt-swap --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    drtpy --verbose contract upgrade ${ADDRESS} --project=${PROJECT} --recall-nonce --pem=${ALICE} \
    --arguments ${WRAPPED_MOA_TOKEN_ID} --gas-limit=100000000 --outfile="upgrade.json" \
    --send --proxy=${PROXY} --chain=${CHAIN_ID} || return
}

issueWrappedMoa() {
    local TOKEN_DISPLAY_NAME=0x577261707065644d6f61  # "WrappedMoa"
    local TOKEN_TICKER=0x574d4f41  # "WMOA"
    local INITIAL_SUPPLY=0x01 # 1
    local NR_DECIMALS=0x12 # 18
    local CAN_ADD_SPECIAL_ROLES=0x63616e4164645370656369616c526f6c6573 # "canAddSpecialRoles"
    local TRUE=0x74727565 # "true"

    drtpy --verbose contract call ${DCDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --value=5000000000000000000 --function="issue" \
    --arguments ${TOKEN_DISPLAY_NAME} ${TOKEN_TICKER} ${INITIAL_SUPPLY} ${NR_DECIMALS} ${CAN_ADD_SPECIAL_ROLES} ${TRUE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

setLocalRoles() {
    local LOCAL_MINT_ROLE=0x44434454526f6c654c6f63616c4d696e74 # "DCDTRoleLocalMint"
    local LOCAL_BURN_ROLE=0x44434454526f6c654c6f63616c4275726e # "DCDTRoleLocalBurn"
    local ADDRESS_HEX = $(drtpy wallet bech32 --decode ${ADDRESS})

    drtpy --verbose contract call ${DCDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments ${WRAPPED_MOA_TOKEN_ID} ${ADDRESS_HEX} ${LOCAL_MINT_ROLE} ${LOCAL_BURN_ROLE} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

wrapMoaBob() {
    drtpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${BOB} \
    --gas-limit=10000000 --value=1000 --function="wrapMoa" \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

unwrapMoaBob() {
    local UNWRAP_MOA_ENDPOINT=0x756e777261704d6f61 # "unwrapMoa"
    local UNWRAP_AMOUNT=0x05

    getWrappedMoaTokenIdentifier
    drtpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${BOB} \
    --gas-limit=10000000 --function="DCDTTransfer" \
    --arguments ${TOKEN_IDENTIFIER} ${UNWRAP_AMOUNT} ${UNWRAP_MOA_ENDPOINT} \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

# views

getWrappedMoaTokenIdentifier() {
    local QUERY_OUTPUT=$(drtpy --verbose contract query ${ADDRESS} --function="getWrappedMoaTokenId" --proxy=${PROXY})
    TOKEN_IDENTIFIER=0x$(jq -r '.[0] .hex' <<< "${QUERY_OUTPUT}")
    echo "Wrapped MOA token identifier: ${TOKEN_IDENTIFIER}"
}

getLockedMoaBalance() {
    drtpy --verbose contract query ${ADDRESS} --function="getLockedMoaBalance" --proxy=${PROXY}
}
