// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract MinterRole is Ownable {
    mapping(address => bool) public minter_role;

    function setMinterRole(address _who, bool _status) public onlyOwner {
        minter_role[_who] = _status;
    }

    modifier onlyMinter() {
        require(minter_role[msg.sender], "Minter role required");
        _;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface ICallistoNFT {
    event NewBid(
        uint256 indexed tokenID,
        uint256 indexed bidAmount,
        bytes data
    );
    event NewPrice(
        uint256 indexed tokenID,
        uint256 indexed priceValue,
        bytes data
    );
    event TokenTrade(
        uint256 indexed tokenID,
        address indexed new_owner,
        address indexed previous_owner,
        uint256 priceInWEI
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event TransferData(bytes data);

    struct Properties {
        // In this example properties of the given NFT are stored
        // in a dynamically sized array of strings
        // properties can be re-defined for any specific info
        // that a particular NFT is intended to store.

        /* Properties could look like this:
        bytes   property1;
        bytes   property2;
        address property3;
        */

        string[] properties;
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function standard() external view returns (string memory);

    function balanceOf(address _who) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transfer(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bool);

    function silentTransfer(
        address _to,
        uint256 _tokenId
    ) external returns (bool);

    function priceOf(uint256 _tokenId) external view returns (uint256);

    function bidOf(
        uint256 _tokenId
    )
        external
        view
        returns (uint256 price, address payable bidder, uint256 timestamp);

    function getTokenProperties(
        uint256 _tokenId
    ) external view returns (Properties memory);

    function setBid(uint256 _tokenId, bytes calldata _data) external payable; // bid amount is defined by msg.value

    function setPrice(
        uint256 _tokenId,
        uint256 _amountInWEI,
        bytes calldata _data
    ) external;

    function withdrawBid(uint256 _tokenId) external returns (bool);

    function getUserContent(
        uint256 _tokenId
    ) external view returns (string memory _content);

    function setUserContent(
        uint256 _tokenId,
        string calldata _content
    ) external returns (bool);
}

abstract contract NFTReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual returns (bytes4);
}

// ExtendedNFT is a version of the CallistoNFT standard token
// that implements a set of function for NFT content management
contract ExtendedNFT is ICallistoNFT, ReentrancyGuard {
    using Address for address;

    event TokenPropertyUpdated(uint tokenID, uint propertyID);

    mapping(uint256 => Properties) private _tokenProperties;

    uint256 public bidLock = 1 days; // Time required for a bid to become withdrawable.

    struct Bid {
        address payable bidder;
        uint256 amountInWEI;
        uint256 timestamp;
    }

    mapping(uint256 => uint256) private _asks; // tokenID => price of this token (in WEI)
    mapping(uint256 => Bid) private _bids; // tokenID => price of this token (in WEI)

    uint256 public next_mint_id;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Reward is always paid based on BID
    modifier checkTrade(uint256 _tokenId, bytes calldata _data) {
        _;
        (uint256 _bid, address payable _bidder, ) = bidOf(_tokenId);
        if (priceOf(_tokenId) > 0 && priceOf(_tokenId) <= _bid) {
            emit TokenTrade(_tokenId, _bidder, ownerOf(_tokenId), _bid);

            bool sent = payable(ownerOf(_tokenId)).send(_bid);

            //bytes calldata _empty;
            delete _bids[_tokenId];
            delete _asks[_tokenId];
            _transfer(ownerOf(_tokenId), _bidder, _tokenId, _data);
        }
    }

    function standard() public view virtual override returns (string memory) {
        return "CallistoNFT";
    }

    function mint() internal returns (uint256 _mintedId) {
        _safeMint(msg.sender, next_mint_id);
        _mintedId = next_mint_id;
        next_mint_id++;

        _configureNFT(_mintedId);
    }

    function priceOf(
        uint256 _tokenId
    ) public view virtual override returns (uint256) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return _asks[_tokenId];
    }

    function bidOf(
        uint256 _tokenId
    )
        public
        view
        virtual
        override
        returns (uint256 price, address payable bidder, uint256 timestamp)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return (
            _bids[_tokenId].amountInWEI,
            _bids[_tokenId].bidder,
            _bids[_tokenId].timestamp
        );
    }

    function getTokenProperties(
        uint256 _tokenId
    ) public view virtual override returns (Properties memory) {
        return _tokenProperties[_tokenId];
    }

    function getTokenProperty(
        uint256 _tokenId,
        uint256 _propertyId
    ) public view virtual returns (string memory) {
        return _tokenProperties[_tokenId].properties[_propertyId];
    }

    function getUserContent(
        uint256 _tokenId
    ) public view virtual override returns (string memory _content) {
        return (_tokenProperties[_tokenId].properties[0]);
    }

    function setUserContent(
        uint256 _tokenId,
        string calldata _content
    ) public virtual override returns (bool success) {
        require(
            msg.sender == ownerOf(_tokenId),
            "NFT: only owner can change NFT content"
        );
        _tokenProperties[_tokenId].properties[0] = _content;
        emit TokenPropertyUpdated(_tokenId, 0);
        return true;
    }

    function _addPropertyWithContent(
        uint256 _tokenId,
        string calldata _content
    ) internal {
        // Check permission criteria

        _tokenProperties[_tokenId].properties.push(_content);

        uint newPropertyID = _tokenProperties[_tokenId].properties.length - 1;

        emit TokenPropertyUpdated(_tokenId, newPropertyID);
    }

    function _modifyProperty(
        uint256 _tokenId,
        uint256 _propertyId,
        string calldata _content
    ) internal {
        _tokenProperties[_tokenId].properties[_propertyId] = _content;

        emit TokenPropertyUpdated(_tokenId, _propertyId);
    }

    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(owner != address(0), "NFT: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return owner;
    }

    /* 
        Price == 0, "NFT not on sale"
        Price > 0, "NFT on sale"
    */
    function setPrice(
        uint256 _tokenId,
        uint256 _amountInWEI,
        bytes calldata _data
    ) public virtual override checkTrade(_tokenId, _data) nonReentrant {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Setting asks is only allowed for owned NFTs!"
        );
        _asks[_tokenId] = _amountInWEI;
        emit NewPrice(_tokenId, _amountInWEI, _data);
    }

    function setBid(
        uint256 _tokenId,
        bytes calldata _data
    ) public payable virtual override checkTrade(_tokenId, _data) nonReentrant {
        (uint256 _previousBid, address payable _previousBidder, ) = bidOf(
            _tokenId
        );
        require(
            msg.value > _previousBid,
            "New bid must exceed the existing one"
        );

        uint256 _bid;
        bool sent;
        // Return previous bid if the current one exceeds it.
        if (_previousBid != 0) {
            sent = _previousBidder.send(_previousBid);
        }
        // Refund overpaid amount if price is greater than 0
        if (priceOf(_tokenId) < msg.value && priceOf(_tokenId) > 0) {
            _bid = priceOf(_tokenId);
        } else {
            _bid = msg.value;
        }
        _bids[_tokenId].amountInWEI = _bid;
        _bids[_tokenId].bidder = payable(msg.sender);
        _bids[_tokenId].timestamp = block.timestamp;

        emit NewBid(_tokenId, _bid, _data);

        // Send back overpaid amount.
        // WARNING: Creates possibility for reentrancy.
        if (priceOf(_tokenId) < msg.value && priceOf(_tokenId) > 0) {
            sent = payable(msg.sender).send(msg.value - priceOf(_tokenId));
        }
    }

    function withdrawBid(
        uint256 _tokenId
    ) public virtual override nonReentrant returns (bool) {
        (uint256 _bid, address payable _bidder, uint256 _timestamp) = bidOf(
            _tokenId
        );
        require(msg.sender == _bidder, "Can not withdraw someone elses bid");
        require(block.timestamp > _timestamp + bidLock, "Bid is time-locked");

        bool sent = _bidder.send(_bid);
        delete _bids[_tokenId];
        emit NewBid(_tokenId, 0, "0x7769746864726177426964");
        return true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function transfer(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public override returns (bool) {
        _transfer(msg.sender, _to, _tokenId, _data);
        emit TransferData(_data);
        return true;
    }

    function silentTransfer(
        address _to,
        uint256 _tokenId
    ) public override returns (bool) {
        require(
            ExtendedNFT.ownerOf(_tokenId) == msg.sender,
            "NFT: transfer of token that is not own"
        );
        require(_to != address(0), "NFT: transfer to the zero address");

        _asks[_tokenId] = 0; // Zero out price on transfer

        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.

        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(msg.sender, _to, _tokenId);

        _balances[msg.sender] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(msg.sender, _to, _tokenId);
        return true;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "NFT: mint to the zero address");
        require(!_exists(tokenId), "NFT: token already minted");
        require(next_mint_id < 1500, "NFTs sold out");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ExtendedNFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual {
        require(
            ExtendedNFT.ownerOf(tokenId) == from,
            "NFT: transfer of token that is not own"
        );
        require(to != address(0), "NFT: transfer to the zero address");

        _asks[tokenId] = 0; // Zero out price on transfer

        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.

        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        if (to.isContract()) {
            NFTReceiver(to).onERC721Received(msg.sender, from, tokenId, data);
        }

        emit Transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _configureNFT(uint256 _tokenId) internal {
        if (_tokenProperties[_tokenId].properties.length == 0) {
            _tokenProperties[_tokenId].properties.push("");
        }
    }
}

interface IClassifiedNFT is ICallistoNFT {
    function setClassForTokenID(uint256 _tokenID, uint256 _tokenClass) external;

    function addNewTokenClass(string memory _property) external;

    function addTokenClassProperties(
        uint256 _propertiesCount,
        uint256 classId
    ) external;

    function modifyClassProperty(
        uint256 _classID,
        uint256 _propertyID,
        string memory _content
    ) external;

    function getClassProperty(
        uint256 _classID,
        uint256 _propertyID
    ) external view returns (string memory);

    function addClassProperty(uint256 _classID) external;

    function getClassProperties(
        uint256 _classID
    ) external view returns (string[] memory);

    function getClassForTokenID(
        uint256 _tokenID
    ) external view returns (uint256);

    function getClassPropertiesForTokenID(
        uint256 _tokenID
    ) external view returns (string[] memory);

    function getClassPropertyForTokenID(
        uint256 _tokenID,
        uint256 _propertyID
    ) external view returns (string memory);

    function mintWithClass(
        uint256 classId
    ) external returns (uint256 _newTokenID);

    function appendClassProperty(
        uint256 _classID,
        uint256 _propertyID,
        string memory _content
    ) external;
}

abstract contract ClassifiedNFT is MinterRole, ExtendedNFT, IClassifiedNFT {
    event ClassPropertyUpdated(uint classID, uint propertyID);
    event TokenClassChanged(uint _tokenID, uint _tokenClass);

    mapping(uint256 => string[]) public class_properties;
    mapping(uint256 => uint256) public token_classes;

    uint256 public nextClassIndex = 0;

    modifier onlyExistingClasses(uint256 classId) {
        require(classId < nextClassIndex, "Queried class does not exist");
        _;
    }

    function setClassForTokenID(
        uint256 _tokenID,
        uint256 _tokenClass
    ) public override onlyOwner {
        token_classes[_tokenID] = _tokenClass;
    }

    function addNewTokenClass(
        string memory _property
    ) public override onlyOwner {
        class_properties[nextClassIndex].push(_property);

        emit ClassPropertyUpdated(nextClassIndex, 0);

        nextClassIndex++;
    }

    function addTokenClassProperties(
        uint256 _propertiesCount,
        uint256 classId
    ) public override onlyOwner {
        for (uint i = 0; i < _propertiesCount; i++) {
            class_properties[classId].push("");
        }
    }

    function modifyClassProperty(
        uint256 _classID,
        uint256 _propertyID,
        string memory _content
    ) public override onlyOwner onlyExistingClasses(_classID) {
        class_properties[_classID][_propertyID] = _content;

        emit ClassPropertyUpdated(_classID, _propertyID);
    }

    function getClassProperty(
        uint256 _classID,
        uint256 _propertyID
    )
        public
        view
        override
        onlyExistingClasses(_classID)
        returns (string memory)
    {
        return class_properties[_classID][_propertyID];
    }

    function addClassProperty(
        uint256 _classID
    ) public override onlyOwner onlyExistingClasses(_classID) {
        class_properties[_classID].push("");
    }

    function addClassPropertyWithContent(
        uint256 _classID,
        string memory _content
    ) public onlyOwner onlyExistingClasses(_classID) {
        class_properties[_classID].push(_content);

        uint newPropertyID = class_properties[_classID].length - 1;

        emit ClassPropertyUpdated(_classID, newPropertyID);
    }

    function getClassProperties(
        uint256 _classID
    )
        public
        view
        override
        onlyExistingClasses(_classID)
        returns (string[] memory)
    {
        return class_properties[_classID];
    }

    function getClassForTokenID(
        uint256 _tokenID
    )
        public
        view
        override
        onlyExistingClasses(token_classes[_tokenID])
        returns (uint256)
    {
        return token_classes[_tokenID];
    }

    function getClassPropertiesForTokenID(
        uint256 _tokenID
    )
        public
        view
        override
        onlyExistingClasses(token_classes[_tokenID])
        returns (string[] memory)
    {
        return class_properties[token_classes[_tokenID]];
    }

    function getClassPropertyForTokenID(
        uint256 _tokenID,
        uint256 _propertyID
    )
        public
        view
        override
        onlyExistingClasses(token_classes[_tokenID])
        returns (string memory)
    {
        return class_properties[token_classes[_tokenID]][_propertyID];
    }

    function mintWithClass(
        uint256 classId
    )
        public
        override
        onlyExistingClasses(classId)
        onlyMinter
        returns (uint256 _newTokenID)
    {
        //_mint(to, tokenId);
        _newTokenID = mint();
        token_classes[_newTokenID] = classId;
    }

    function appendClassProperty(
        uint256 _classID,
        uint256 _propertyID,
        string memory _content
    ) public override onlyOwner onlyExistingClasses(_classID) {}
}

contract CharityNFT is ExtendedNFT, ClassifiedNFT {
    function initialize(string memory name_, string memory symbol_) external {
        require(_owner == address(0), "Already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        bidLock = 1 days;
        _name = name_;
        _symbol = symbol_;
    }

    function addPropertyWithContent(
        uint256 _tokenId,
        string calldata _content
    ) public onlyMinter {
        _addPropertyWithContent(_tokenId, _content);
    }
}

contract ActivatedByOwner is Ownable {
    bool public active = true;

    function setActive(bool _active) public onlyOwner {
        active = _active;
    }

    modifier onlyActive() {
        require(active, "This contract is deactivated by owner");
        _;
    }
}

contract NFTMulticlassPermissiveAuction is ActivatedByOwner {
    event AuctionCreated(
        uint256 indexed tokenClassAuctionID,
        uint256 timestamp
    );
    event TokenSold(
        uint256 indexed tokenID,
        uint256 indexed tokenClassID,
        address indexed buyer
    );
    event NFTContractSet(
        address indexed newNFTContract,
        address indexed oldNFTContract
    );
    event RevenueWithdrawal(uint256 amount);

    address public nft_contract;

    struct NFTAuctionClass {
        uint256 amount_sold;
        uint256 start_timestamp;
        uint256 priceInWei;
    }

    mapping(uint256 => NFTAuctionClass) public auctions; // Mapping from classID (at NFT contract) to set of variables
    //  defining the auction for this token class.

    address payable public revenue =
        payable(0x01000B5fE61411C466b70631d7fF070187179Bbf); // This address has the rights to withdraw funds from the auction.

    constructor() {
        _owner = msg.sender;
    }

    function createNFTAuction(
        uint256 _classID,
        uint256 _start_timestamp,
        uint256 _priceInWei
    ) public onlyOwner {
        auctions[_classID].amount_sold = 0;
        auctions[_classID].start_timestamp = _start_timestamp;
        auctions[_classID].priceInWei = _priceInWei;

        emit AuctionCreated(_classID, block.timestamp);
    }

    function setRevenueAddress(
        address payable _revenue_address
    ) public onlyOwner {
        revenue = _revenue_address;
    }

    function setNFTContract(address _nftContract) public onlyOwner {
        emit NFTContractSet(_nftContract, nft_contract);

        nft_contract = _nftContract;
    }

    receive() external payable {}

    function buyNFT(uint _classID) public payable onlyActive {
        require(
            msg.value >= auctions[_classID].priceInWei,
            "Insufficient funds"
        );

        uint256 _mintedId = ClassifiedNFT(nft_contract).mintWithClass(_classID);
        auctions[_classID].amount_sold++;
        configureNFT(_mintedId);

        ClassifiedNFT(nft_contract).transfer(msg.sender, _mintedId, "");

        emit TokenSold(_mintedId, _classID, msg.sender);
    }

    function configureNFT(uint256 _tokenId) internal {
        CharityNFT(nft_contract).addPropertyWithContent(
            _tokenId,
            string(
                abi.encodePacked(
                    "Donated: ",
                    toString(msg.value / 1e18),
                    " CLO at ",
                    toString(block.timestamp)
                )
            )
        );
    }

    function withdrawRevenue() public {
        require(
            msg.sender == revenue,
            "This action requires revenue permission"
        );

        emit RevenueWithdrawal(address(this).balance);

        bool sent = revenue.send(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15-L35

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
