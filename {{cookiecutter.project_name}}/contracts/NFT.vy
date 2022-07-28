# @version 0.3.3

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC165
implements: ERC721

############ ERC-165 #############
# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[{{ 2 + (1 if cookiecutter.metadata == "y" else 0) + (1 if cookiecutter.permitable == "y" else 0) }}]) = [
    0x01ffc9a7,  # ERC165 interface ID of ERC165
    0x80ac58cd,  # ERC165 interface ID of ERC721
{%- if cookiecutter.metadata == 'y' %}
    0x5b5e139f,  # ERC165 interface ID of ERC721 Metadata Extension
{%- endif %}
{%- if cookiecutter.permitable == 'y' %}
    0x5604e225,  # ERC165 interface ID of ERC4494
{%- endif %}
]

############ ERC-721 #############

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            operator: address,
            owner: address,
            tokenId: uint256,
            data: Bytes[1024]
        ) -> bytes32: view

# Interface for ERC721Metadata

interface ERC721Metadata:
	def name() -> String[64]: view

	def symbol() -> String[32]: view

	def tokenURI(
		_tokenId: uint256
	) -> String[128]: view

interface ERC721Enumerable:

	def totalSupply() -> uint256: view

	def tokenByIndex(
		_index: uint256
	) -> uint256: view

	def tokenOfOwnerByIndex(
		_address: address,
		_index: uint256
	) -> uint256: view


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param owner Sender of NFT (if address is zero address it indicates token creation).
# @param receiver Receiver of NFT (if address is zero address it indicates token destruction).
# @param tokenId The NFT that got transfered.
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param owner Owner of NFT.
# @param approved Address that we are approving.
# @param tokenId NFT which we are approving.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param owner Owner of NFT.
# @param operator Address to which we are setting operator rights.
# @param approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

tokenName: immutable(String[64])
tokenSymbol: immutable(String[32])
baseTokenURI: immutable(String[64])

# @dev current number of tokens
totalSupply: uint256

# @dev Maximum supply of token
MAX_SUPPLY: constant(uint256) = {{cookiecutter.premint_amount}}

# @dev creator of contract
owner: public(address)

{%- if cookiecutter.minters == 'y' %}
# @dev a hashmap of operators
isMinter: public(HashMap[address, bool])
{%- endif %}

# @dev TokenID => owner
idToOwner: public(HashMap[uint256, address])

# @dev Mapping from NFT ID to approved address.
idToApprovals: public(HashMap[uint256, address])

# @dev Mapping from owner address to count of their tokens.
balanceOf: public(HashMap[address, uint256])

# @dev Mapping from owner address to mapping of operator addresses.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])

idToURI: public(HashMap[uint256, String[64]])

{%- if cookiecutter.permitable == 'y' %}
############ ERC-4494 ############

# @dev Mapping of TokenID to nonce values used for ERC4494 signature verification
nonces: public(HashMap[uint256, uint256])

DOMAIN_SEPARATOR: public(bytes32)

EIP712_DOMAIN_TYPEHASH: constant(bytes32) = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
)
EIP712_DOMAIN_NAMEHASH: constant(bytes32) = keccak256("Owner NFT")
EIP712_DOMAIN_VERSIONHASH: constant(bytes32) = keccak256("1")
{%- endif %}


# ERC20 Token Metadata
IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

@external
def __init__(
    name: String[64],
    symbol: String[32],
    baseURI: String[64],
):
    
    """
    @dev Contract constructor.
    """
    self.owner = msg.sender
    tokenName = name
    tokenSymbol = symbol
    baseTokenURI = baseURI

{%- if cookiecutter.permitable == 'y' %}
    # ERC712 domain separator for ERC4494
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            EIP712_DOMAIN_TYPEHASH,
            EIP712_DOMAIN_NAMEHASH,
            EIP712_DOMAIN_VERSIONHASH,
            chain.id,
            self,
        )
    )
{%- endif %}

{%- if cookiecutter.metadata == 'y' %}
# ERC721 Metadata Extension
@pure
@external
def name() -> String[64]:
    return tokenName

@pure
@external
def symbol() -> String[32]:
    return tokenSymbol

@view
@external
def baseURI() -> String[64]:
    return baseTokenURI

@internal
def _uint_to_string(val: uint256) -> String[78]:
    """
    @dev skelletOr
    reference: https://github.com/curvefi/curve-veBoost/blob/0e51be10638df2479d9e341c07fafa940ef58596/contracts/VotingEscrowDelegation.vy#L423
    """
    # NOTE: Odd that this works with a raw_call inside, despite being marked
    # a pure function
    if val == 0:
        return "0"

    buffer: Bytes[78] = b""
    digits: uint256 = 78

    for i in range(78):
        # go forward to find the # of digits, and set it
        # only if we have found the last index
        if digits == 78 and val / 10 ** i == 0:
            digits = i

        char_int: uint256 = ((val / 10 ** (77 - i)) % 10) + 48
        char: Bytes[1] = slice(convert(char_int, bytes32), 31, 1)
        buffer = raw_call(
            IDENTITY_PRECOMPILE,
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])
{%- endif %}

# {%- if cookiecutter.set_token_uri == 'y' %}
# @internal
# def _setTokenURI(tokenId: uint256, tokenURI: String[64]):
#     """
#     @dev Set the URI for a token
#          Throws if the token ID does not exist
#     """
#     assert self.idToOwner[tokenId] != ZERO_ADDRESS
#     self.idToURI[tokenId] = tokenURI
# {%- endif %}

@view
@external
def tokenURI(tokenId: uint256) -> String[179]:
{%- if cookiecutter.updatable_uri == 'y' %}
    return concat(baseTokenURI, "/" , self._uint_to_string(tokenId))
    {%- else%}
    return concat(baseTokenURI_default, "/" , self._uint_to_string(tokenId))
{%- endif %}

{%- if cookiecutter.permitable == 'y' %}
@external
def setDomainSeparator():
    """
    @dev Update the domain separator in case of a hardfork where chain ID changes
    """
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            EIP712_DOMAIN_TYPEHASH,
            EIP712_DOMAIN_NAMEHASH,
            EIP712_DOMAIN_VERSIONHASH,
            chain.id,
            self,
        )
    )
{%- endif %}

############ ERC-165 #############

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES


##### ERC-721 VIEW FUNCTIONS #####

@view
@external
def ownerOf(tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[tokenId]
    # Throws if `tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner


@view
@external
def getApproved(tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId ID of the NFT to query the approval of.
    """
    # Throws if `tokenId` is not a valid NFT
    assert self.idToOwner[tokenId] != ZERO_ADDRESS
    return self.idToApprovals[tokenId]

@view
@external
def tokenByIndex(index: uint256) -> uint256:
    """
    @dev Get token by index
         Throws if 'index' is larger than totalSupply()
    """
    # NOTE: This is more gas-heavy than maintaining the properties in storage.
    #       However, we almost always reference this value off-chain,
    #       so the cost doesn't matter.
    assert index <= self.totalSupply  # NOTE: This prevents indexing un-minted tokens
    assert index > 0

    burnt_offset: uint256 = 0
    for raw_idx in range(MAX_SUPPLY):
        # Iterated over all possible mintable tokens (may not be minted yet)
        if self.idToOwner[raw_idx] == ZERO_ADDRESS:
            # This token has been burnt or not minted yet
            burnt_offset += 1
        
        if raw_idx - burnt_offset == index:
            return raw_idx
    return index + burnt_offset
    #raise UNREACHABLE  # Shouldn't ever reach this (see NOTE above)


@view
@external
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
    """
    @dev Get token by index
         Throws if 'index' is larger than balance of 'owner'
         Throws if value has been set to 0
    """
    # NOTE: This is more gas-heavy than maintaining the properties in storage.
    #       However, we almost always reference this value off-chain,
    #       so the cost doesn't matter.
    # NOTE: invariant `balanceOf(owner) <= totalSupply`
    assert index <= self.balanceOf[owner]  # NOTE: This prevents indexing un-minted tokens
    assert index > 0

    owner_offset: uint256 = 0
    for raw_idx in range(MAX_SUPPLY):
        # Iterated over all possible mintable tokens (may not be minted yet)
        if self.idToOwner[raw_idx] != owner:
            # This token is not owned by `owner`
            # NOTE: This also avoids burnt tokens as well as ones that are not minted yet
            owner_offset += 1
        
        if raw_idx - owner_offset == index:
            return raw_idx
    return index + owner_offset

    #raise UNREACHABLE  # Shouldn't ever reach this (see NOTE above)

### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrOwner(spender: address, tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[tokenId]

    if owner == spender:
        return True

    if spender == self.idToApprovals[tokenId]:
        return True

    if (self.isApprovedForAll[owner])[spender]:
        return True

    return False

@internal
def _transferFrom(owner: address, receiver: address, tokenId: uint256, sender: address):
    """
    @dev Execute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         address for thisassert self.idToOwner[tokenId] == owner NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `receiver` is the zero address.
         Throws if `owner` is not the current owner.
         Throws if `tokenId` is not a valid NFT.
    """
    # Check requirements
    assert self._isApprovedOrOwner(sender, tokenId)
    assert receiver != ZERO_ADDRESS
    assert owner != ZERO_ADDRESS
    assert self.idToOwner[tokenId] == owner

    # Reset approvals, if any
    if self.idToApprovals[tokenId] != ZERO_ADDRESS:
        self.idToApprovals[tokenId] = ZERO_ADDRESS

    # EIP-4494: increment nonce on transfer for safety
    self.nonces[tokenId] += 1

    # Change the owner
    self.idToOwner[tokenId] = receiver

    # Change count tracking
    self.balanceOf[owner] -= 1
    self.balanceOf[receiver] += 1

    # Log the transfer
    log Transfer(owner, receiver, tokenId)


@external
def transferFrom(owner: address, receiver: address, tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `owner` is not the current owner.
         Throws if `receiver` is the zero address.
         Throws if `tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `receiver` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param owner The current owner of the NFT.
    @param receiver The new owner.
    @param tokenId The NFT to transfer.
    """
    self._transferFrom(owner, receiver, tokenId, msg.sender)


@external
def safeTransferFrom(
        owner: address,
        receiver: address,
        tokenId: uint256,
        data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `owner` is not the current owner.
         Throws if `receiver` is the zero address.
         Throws if `tokenId` is not a valid NFT.
         If `receiver` is a smart contract, it calls `onERC721Received` on `receiver` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param owner The current owner of the NFT.
    @param receiver The new owner.
    @param tokenId The NFT to transfer.
    @param data Additional data with no specified format, sent in call to `receiver`.
    """
    self._transferFrom(owner, receiver, tokenId, msg.sender)
    if receiver.is_contract: # check if `receiver` is a contract address
        returnValue: bytes32 = ERC721Receiver(receiver).onERC721Received(msg.sender, owner, tokenId, data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


@external
def approve(operator: address, tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `operator` is the current owner. (NOTE: This is not written the EIP)
    @param operator Address to be approved for the given NFT ID.
    @param tokenId ID of the token to be approved.
    """
    # Throws if `tokenId` is not a valid NFT
    owner: address = self.idToOwner[tokenId]
    assert owner != ZERO_ADDRESS

    # Throws if `operator` is the current owner
    assert operator != owner

    # Throws if `msg.sender` is not the current owner, or is approved for all actions
    assert owner == msg.sender or (self.isApprovedForAll[owner])[msg.sender]

    self.idToApprovals[tokenId] = operator
    log Approval(owner, operator, tokenId)

{%- if cookiecutter.clear_approval == 'y' %}
@internal
def _clearApproval(owner: address, tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `owner` is not the current owner.
    """
    # Throws if `owner` is not the current owner
    assert self.idToOwner[tokenId] == owner
    if self.idToApprovals[tokenId] != ZERO_ADDRESS:
        # Reset approvals
        self.idToApprovals[tokenId] = ZERO_ADDRESS
{%- endif %}

{%- if cookiecutter.permitable == 'y' %}
@external
def permit(spender: address, tokenId: uint256, deadline: uint256, sig: Bytes[65]) -> bool:
    """
    @dev Allow a 3rd party to approve a transfer via EIP-721 message
        Raises if permit has expired
        Raises if `tokenId` is unowned
        Raises if permit is not signed by token owner
        Raises if `nonce` is not the current expected value
        Raises if `sig` is not a supported signature type
    @param spender The approved spender of `tokenId` for the permit
    @param tokenId The token that is being approved
        NOTE: signer is checked against this token's owner
    @param deadline The time limit for which the message is valid for
    @param sig The signature for the message, either in vrs or EIP-2098 form
    @return bool If the operation is successful
    """
    # Permit is still valid
    assert block.timestamp <= deadline

    # Ensure the token is owned by someone
    owner: address = self.idToOwner[tokenId]
    assert owner != ZERO_ADDRESS

    # Nonce for given token (signer must ensure they use latest)
    nonce: uint256 = self.nonces[tokenId]

    # Compose EIP-712 message
    message: bytes32 = keccak256(
        _abi_encode(
            0x1901,
            self.DOMAIN_SEPARATOR,
            keccak256(
                _abi_encode(
                    keccak256(
                        "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
                    ),
                    spender,
                    tokenId,
                    nonce,
                    deadline,
                )
            )
        )
    )

    # Validate signature
    v: uint256 = 0
    r: uint256 = 0
    s: uint256 = 0

    if len(sig) == 65:
        # Normal encoded VRS signatures
        v = convert(slice(sig, 0, 1), uint256)
        r = convert(slice(sig, 1, 32), uint256)
        s = convert(slice(sig, 33, 32), uint256)

    elif len(sig) == 64:
        # EIP-2098 compact signatures
        r = convert(slice(sig, 0, 32), uint256)
        v = convert(slice(sig, 33, 1), uint256)
        s = convert(slice(sig, 34, 31), uint256)

    else:
        raise  # Other schemes not supported

    # Ensure owner signed permit
    assert ecrecover(message, v, r, s) == owner

    self.nonces[tokenId] = nonce + 1
    self.idToApprovals[tokenId] = spender

    return True

{%- endif %}

@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
    @notice This works even if sender doesn't own any tokens at the time.
    @param operator Address to add to the set of authorized operators.
    @param approved True if the operators is approved, false to revoke approval.
    """
    self.isApprovedForAll[msg.sender][operator] = approved
    log ApprovalForAll(msg.sender, operator, approved)

{%- if cookiecutter.minters  == 'y' %}
@external
def addMinter(minter: address):
    assert msg.sender == self.owner
    self.isMinter[minter] = True
{%- endif %}

{%- if cookiecutter.mintable == 'y' %}
@external
def mint(receiver: address, tokenId: uint256) -> uint256:
    """
    @dev Create a new Owner NFT
    @notice `tokenId` cannot be owned by someone because of hash production.
    @return uint256 Computed TokenID of new Portfolio.
    """

{%- if (cookiecutter.minters == 'y') and (cookiecutter.mintable == 'y') %}
    assert msg.sender == self.owner or self.isMinter[msg.sender], "Access is denied."
{%- endif %}
    assert self.idToOwner[tokenId] == ZERO_ADDRESS  # Sanity check

    self.idToOwner[tokenId] = receiver
    self.balanceOf[receiver] += 1

    log Transfer(ZERO_ADDRESS, receiver, tokenId)
    return tokenId
{%- endif %}
