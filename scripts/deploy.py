from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)

# publish_source here tells brownie to verify our contract for us
# You can see comments on the success of this as you deploy
# When you deploy to Ganache CLI and then close it, you'll need to clear out the deployments folder for that network.
# Otherwise your dev env will think it still exists and try to connect to it
def deploy_fund_me():
    account = get_account()
    # development network is Ganache CLI from brownie, which doesn't know about Chainlink's data feed for Rinkeby
    # same with the Ganache GUI
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        # -1 syntax means use the most recently deployed object
        price_feed_address = MockV3Aggregator[-1].address

    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {fund_me.address}")
    return fund_me


def main():
    deploy_fund_me()
