import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface NFT {
    function transfer(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bool);

    function mintWithClass(
        uint256 classId
    ) external returns (uint256 _newTokenID);

    function addPropertyWithContent(
        uint256 _tokenId,
        string calldata _content
    ) external;
}

// SPDX-License-Identifier: GPL

pragma solidity ^0.8.19;

contract SaleWithAmountLimit is Ownable {
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
        uint256 hard_cap;
        uint256 minPriceInEther;
        uint256 maxPriceInEther;
    }

    mapping(uint256 => NFTAuctionClass) public auctions; // Mapping from classID (at NFT contract) to set of variables
    //  defining the auction for this token class.

    address payable public revenue =
        payable(0x01000B5fE61411C466b70631d7fF070187179Bbf); // This address has the rights to withdraw funds from the auction.

    constructor() {}

    function createNFTAuction(
        uint256 _classID,
        uint256 _hard_cap,
        uint256 _priceInEther
    ) public onlyOwner {
        auctions[_classID].amount_sold = 0;
        auctions[_classID].hard_cap = _hard_cap;
        auctions[_classID].minPriceInEther = _priceInEther * 1e18;
        auctions[_classID].maxPriceInEther = _priceInEther * 1e18;

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

    function buyNFT(uint _classID) public payable {
        require(
            msg.value >= auctions[_classID].minPriceInEther,
            'Error: Insufficient funds'
        );
        require(
            msg.value < auctions[_classID].maxPriceInEther ||
                auctions[_classID].maxPriceInEther == 0,
            'Error: Overpaid'
        );
        require(
            auctions[_classID].amount_sold < auctions[_classID].hard_cap,
            'Error: NFT sold out'
        );

        uint256 _mintedId = NFT(nft_contract).mintWithClass(_classID);
        auctions[_classID].amount_sold++;
        configureNFT(_mintedId);

        NFT(nft_contract).transfer(msg.sender, _mintedId, '');

        emit TokenSold(_mintedId, _classID, msg.sender);
    }

    function configureNFT(uint256 _tokenId) internal {
        NFT(nft_contract).addPropertyWithContent(
            _tokenId,
            string.concat(
                'Donated: ',
                toString(msg.value / 1e18),
                ' CLO at ',
                toString(block.timestamp)
            )
        );
    }

    function withdrawRevenue() public {
        require(
            msg.sender == revenue,
            'This action requires revenue permission'
        );

        emit RevenueWithdrawal(address(this).balance);

        revenue.transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15-L35

        if (value == 0) {
            return '0';
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
