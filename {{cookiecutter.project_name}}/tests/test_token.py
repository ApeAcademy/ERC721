import ape


def test_erc165(nft):
    # ERC165 interface ID of ERC165
    assert nft.supportsInterface("0x01ffc9a7")

    # ERC165 specifies that this is never supported
    assert not nft.supportsInterface("0xffffffff")

    # ERC165 interface ID of ERC721
    assert nft.supportsInterface("0x80ac58cd")
{%- if cookiecutter.metadata == 'y' %}

    # ERC165 interface ID of ERC721 Metadata Extension
    assert nft.supportsInterface("0x5b5e139f")
{%- endif %}
{%- if cookiecutter.permitable == 'y' %}

    # ERC165 interface ID of ERC4494
    assert nft.supportsInterface("0x5604e225")
{%- endif %}


def test_init(nft, owner):
    assert nft.balanceOf(owner) == 0
    with ape.reverts():
        assert nft.ownerOf(0)

def test_total_supply(nft, owner):
    assert nft.totalSupply() == 0
    nft.mint(owner, 0, sender=owner)
    assert nft.totalSupply() == 1
