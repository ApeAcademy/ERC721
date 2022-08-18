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


def test_mint_and_add_minter(nft, owner, receiver):
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0
    nft.mint(receiver,sender=owner)
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 1
    assert nft.ownerOf(1) == receiver.address
    nft.addMinter(receiver, sender=owner)
    nft.mint(receiver,sender=receiver)
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 2
    assert nft.ownerOf(2) == receiver.address


def test_total_supply(nft, owner):
    assert nft.totalSupply() == 0
    nft.mint(owner, sender=owner)
    assert nft.totalSupply() == 1


def test_transfer(nft, owner, receiver):
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0
    nft.mint(owner, sender=owner)
    assert nft.balanceOf(owner) == 1
    assert nft.ownerOf(1) == owner.address
    nft.transferFrom(owner, receiver, 1, sender=owner)
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 1
    assert nft.ownerOf(1) == receiver.address
    nft.transferFrom(receiver, owner, 1, sender=receiver)
    assert nft.balanceOf(receiver) == 0
    assert nft.balanceOf(owner) == 1
    assert nft.ownerOf(1) == owner.address


def test_incorrect_signer_transfer(nft, owner, receiver):
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0
    nft.mint(owner, sender=owner)
    with ape.reverts():
        nft.transferFrom(owner,receiver,1,sender=receiver)    
    assert nft.balanceOf(receiver) == 0
    assert nft.balanceOf(owner) == 1
    assert nft.ownerOf(1) == owner.address


def test_incorrect_signer_minter(nft, owner, receiver):
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0
    with ape.reverts():
        nft.mint(owner, sender=receiver)
    assert nft.isMinter(receiver) == False
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0


def test_approve_transfer(nft, owner, receiver):
    assert nft.balanceOf(owner) == 0
    assert nft.balanceOf(receiver) == 0
    nft.mint(owner, sender=owner)
    assert nft.balanceOf(receiver) == 0
    assert nft.balanceOf(owner) == 1
    assert nft.ownerOf(1) == owner.address
    
    with ape.reverts():
        nft.approve(receiver, 1, sender=receiver)
        nft.transferFrom(owner, receiver, 1, sender=receiver)
    assert nft.balanceOf(receiver) == 0
    assert nft.balanceOf(owner) == 1
    assert nft.ownerOf(1) == owner.address

    nft.approve(receiver, 1, sender=owner)
    assert nft.getApproved(1) == receiver
    nft.transferFrom(owner, receiver, 1, sender=receiver)
    assert nft.balanceOf(receiver) == 1
    assert nft.balanceOf(owner) == 0
    assert nft.ownerOf(1) == receiver.address


def test_uri(nft, owner):

    assert nft.baseURI() == "{{cookiecutter.base_uri}}"
    nft.mint(owner, sender=owner)
    assert nft.tokenURI(1) == "{{cookiecutter.base_uri}}/1"
    
    {%- if cookiecutter.updatable_uri == 'y' %}

    nft.setBaseURI("new base uri", sender=owner)
    assert nft.baseURI() == "new base uri"
    assert nft.tokenURI(1) == "new base uri/1"
    
    {%- endif %}