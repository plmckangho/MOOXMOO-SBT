// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IERC5192.sol";
import "./utils/AccessLock.sol";

contract MooxmooSBT is ERC721, ERC721Enumerable, Ownable, AccessLock {
    
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter public nftCounter;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    mapping(uint256 => bool) _locked;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @notice currently SBT Contract does not emit Unlocked event
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Check if the token is already locked
    /// @dev If the token is locked, transmission is not possible.
    /// @param owner owner address.
    /// @param newBaseURI new base URI.
    event BaseUriUpdated(address indexed owner, string newBaseURI);

    /// @notice Check if the token is already locked
    /// @dev If the token is locked, transmission is not possible.
    /// @param _tokenId The identifier for an SBT.
    modifier IsTransferAllowed(uint256 _tokenId) {
        require(!_locked[_tokenId], "Tokens are soul-bound and cannot be transferred");
        _;
    }

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param _tokenId The identifier for an SBT.
    function locked(uint256 _tokenId) external view returns (bool) {
        require(ownerOf(_tokenId) != address(0));
        return _locked[_tokenId];
    }

    /// @notice An address can own multiple SBTs
    /// @dev If Only one SBT is possible per address then 
    /// delete the comment of require statement below
    /// @param _recipient SBT receiving address
    function mint(address _recipient) public onlyMinter {
        //require(balanceOf(_recipient) == 0, "Only one SBT is possible per address");        
        require(_recipient != address(0), "Invalid receive address");
        nftCounter.increment();
        uint256 tokenId = nftCounter.current();

        _locked[tokenId] = true;
        emit Locked(tokenId);

        _safeMint(_recipient, tokenId);
    }

    /// @notice batch minting SBTs
    /// @dev If Only one SBT is possible per address then 
    /// delete the comment of require statement below
    /// @param _recipient[] an array of SBT receiving address 
    function mintMultiple(address[] calldata _recipient)
        external
        onlyMinter
    {
        uint256 mintLength = _recipient.length;
        for(uint256 i; i < mintLength; i++){
            //require(balanceOf(_recipient[i]) == 0, "Only one SBT is possible per address");        
            require(_recipient[i] != address(0), "Invaid receive address");
            mint(_recipient[i]);
        }
    }

    function burn(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "Only owner can burn");
        _burn(_tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(_tokenId) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(_tokenId) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(IERC721, ERC721) IsTransferAllowed(_tokenId) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
        emit BaseUriUpdated(msg.sender, _newBaseURI);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns(string memory)
    {
        require(_exists(_tokenId), "Non-existent Token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }
 
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }
}