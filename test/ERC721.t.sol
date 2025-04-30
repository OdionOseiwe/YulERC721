// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function mint(address to, uint256 tokenId) external;
}


contract ERC721Test is Test {
    YulDeployer yulDeployer = new YulDeployer();
    address alice;
    address bob;
    IERC721 eRC721Contract;

    function setUp() public {
        eRC721Contract = IERC721(yulDeployer.deployContract("ERC721"));
        alice = vm.addr(1); 
        bob = vm.addr(2);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        vm.label(address(this), "ERC721Test");
    }

    function testMint()   public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(address(alice), 2);
        eRC721Contract.mint(vm.addr(100), 1);
        eRC721Contract.mint(vm.addr(999), 3);
        eRC721Contract.mint(vm.addr(101), 4);

        assertEq(eRC721Contract.balanceOf(address(alice)), 1);
        assertEq(eRC721Contract.balanceOf(vm.addr(100)), 1);
        assertEq(eRC721Contract.balanceOf(vm.addr(999)), 1);
        assertEq(eRC721Contract.balanceOf(vm.addr(101)), 1);

    }

    function testMintTwice() public {
        vm.startPrank(address(alice));
        eRC721Contract.mint(address(alice), 2);
        eRC721Contract.mint(address(alice), 1);
        vm.expectRevert();
        eRC721Contract.mint(address(alice), 2);
    }

    function testOwnerOf() public {
        eRC721Contract.mint(vm.addr(999), 3);
        eRC721Contract.mint(vm.addr(101), 4);
        assertEq(eRC721Contract.ownerOf(3), vm.addr(999));
        assertEq(eRC721Contract.ownerOf(4), vm.addr(101));
    }

    function testRevertAdressZero() public {
        eRC721Contract.mint(vm.addr(999), 3);
        vm.expectRevert();
        eRC721Contract.mint(address(0), 4);
    }

    function testApprove() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(vm.addr(100), 1);
        eRC721Contract.mint(vm.addr(999), 3);
        eRC721Contract.mint(vm.addr(101), 4);

        eRC721Contract.approve(bob,2);
        assertEq(eRC721Contract.getApproved(2),bob);
    }

    function testApprovalForAll() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(vm.addr(100), 1);
        eRC721Contract.mint(vm.addr(999), 3);
        eRC721Contract.mint(vm.addr(101), 4);

        eRC721Contract.setApprovalForAll(bob,true);
        assertEq(eRC721Contract.isApprovedForAll(alice,bob),true);
    }

    function testRevertSameAdressIsApprovalForAll() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(vm.addr(100), 1);
        eRC721Contract.mint(vm.addr(999), 3);
        eRC721Contract.mint(vm.addr(101), 4);

        eRC721Contract.setApprovalForAll(bob,true);
        vm.expectRevert();
        eRC721Contract.setApprovalForAll(alice,true);

    }

    function testTransferFrom() public {
        vm.startPrank(address(alice));
        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);

        eRC721Contract.setApprovalForAll(bob,true);
        vm.stopPrank();

        vm.startPrank(address(bob));
        eRC721Contract.transferFrom(alice, bob, 2);
        assertEq(eRC721Contract.ownerOf(2), bob);
        assertEq(eRC721Contract.balanceOf(alice), 3);
        assertEq(eRC721Contract.balanceOf(bob), 1);
        assertEq(eRC721Contract.getApproved(2),address(0));

    }

    function testTransferFromTwice() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);
       
        eRC721Contract.setApprovalForAll(bob,true);
        assertEq(eRC721Contract.isApprovedForAll(alice,bob),true);
        vm.stopPrank();

        vm.startPrank(address(bob));
        eRC721Contract.transferFrom(alice, bob,2); 
        eRC721Contract.transferFrom(alice, bob,1); 
        assertEq(eRC721Contract.ownerOf(2),bob);
        assertEq(eRC721Contract.ownerOf(1),bob);
        assertEq(eRC721Contract.balanceOf(alice), 2);
        assertEq(eRC721Contract.balanceOf(bob), 2);
        assertEq(eRC721Contract.getApproved(2), address(0));

        vm.expectRevert();
        eRC721Contract.transferFrom(alice, bob,2); 

    }

    function testApproveTransferFrom() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(address(alice), 2);
        eRC721Contract.mint(address(alice), 1);
        eRC721Contract.mint(address(alice), 3);
        eRC721Contract.mint(address(alice), 4);

        eRC721Contract.approve(bob,2);
        assertEq(eRC721Contract.getApproved(2),bob);
        vm.stopPrank();

        vm.startPrank(address(bob));
        eRC721Contract.transferFrom(alice, bob,2); 
        vm.stopPrank();
    }

    /// like transfer in ERC20 token, so far the spender is the owner
    function testTransferFromWithoutApproval() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);

        eRC721Contract.transferFrom(alice, bob,2); 

    }

    /// Reverts because the spender is not the owner and he is not approved
    function testRevertTransferFormWithoutApproval() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);

        vm.stopPrank();

        vm.startPrank(address(bob));
        vm.expectRevert();
        eRC721Contract.transferFrom(alice, bob,2); 

    }

    function testSafeTransferFromWithoutData() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);

        vm.stopPrank();

        vm.startPrank(address(bob));
        vm.expectRevert();
        eRC721Contract.safeTransferFrom(alice, bob, 2, "");
    }

    function testSafeTransferFromWithData() public {
        vm.startPrank(address(alice));

        eRC721Contract.mint(alice, 2);
        eRC721Contract.mint(alice, 1);
        eRC721Contract.mint(alice, 3);
        eRC721Contract.mint(alice, 4);

        vm.stopPrank();

        vm.startPrank(address(bob));
        vm.expectRevert();
        eRC721Contract.safeTransferFrom(alice, bob, 2, "0x123456");
    }

}


