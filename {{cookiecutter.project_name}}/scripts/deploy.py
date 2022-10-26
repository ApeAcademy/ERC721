from ape import project
from ape.cli import get_user_selected_account
import click
from ape.cli import network_option, NetworkBoundCommand, ape_cli_context
from ape.api.networks import LOCAL_NETWORK_NAME


# default connect to a provider
def main():
    account = get_user_selected_account()
    account.deploy(project.NFT)


#perk you can add args unlike main method
@click.command(cls=NetworkBoundCommand)
@ape_cli_context()
@network_option()
# cli_ctx must go first
def cli(cli_ctx, network):
    """
    Deploy the nft
    """
    network = cli_ctx.provider.network.name
    if network == LOCAL_NETWORK_NAME or network.endswith("-fork"):
        account = cli_ctx.account_manager.test_accounts[0]
    else:
        account = get_user_selected_account()
    
    account.deploy(project.NFT)
