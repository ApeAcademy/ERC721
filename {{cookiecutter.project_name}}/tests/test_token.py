import ape
from vyper.interfaces import ERC721

implements: ERC721



def test_no_portfolio(owner, accounts):
    a = accounts[0]
    assert owner.balanceOf(a) == 0
    with ape.reverts():
        owner.estimatedValue(0)