/// @title ERC-721 Token Contract in YUL (Assembly)
/// @Odion Oseiwe
///
///  An ERC-721 token contract implemented in YUL (Assembly) language

// ╔══════════════════════════════════════════╗
// ║                 ERC721                   ║
// ╚══════════════════════════════════════════╝
object "ERC721" {
  code {
      // Deploy-time initialization
      sstore(0x00, 0x0E)
      // Store string content in slot 1
      sstore(0x01, 0x45524337323159756c546f6b656e000000000000000000000000000000000000)  // name 
      sstore(0x02, 0x03)
      sstore(0x03, 0x4559540000000000000000000000000000000000000000000000000000000000) // token symbol in slot 3
      
      // Copy runtime code to memory and return
      datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
      return(0, datasize("Runtime"))
  }

  object "Runtime" {
      code {
        // load slot where
        function sOwnersSlot() -> slot{ slot := 5}
        function sBalancesSlot() -> slot{ slot := 1}
        function sSymbolSlot() -> slot{ slot := 3}
        function sNameSlot() -> slot{ slot := 6}
        function stokenApprovalsSlot() -> slot{ slot := 7}
        function sOperatorApprovalsSlot() -> slot{slot := 8}

        // Function dispatcher
        let selector := shr(224, calldataload(0))
        switch selector

        // name() -> 0x06fdde03
        case 0x06fdde03 {
            mstore(0x00, sload(0x01))
            return(0x00, 0x20)
        }

        // symbol() -> 0x95d89b41
        case 0x95d89b41 {
            mstore(0x00, sload(0x03))
            return(0x00, 0x20)
        }

        // balanceOf(address) -> 0x70a08231
        case 0x70a08231{
             returnUint(balanceOf(decodeAsAddress(0)))
        }

         // ownerOf(uint256) -> 0x6352211e
        case 0x6352211e{
            returnUint(ownerOf(decodeAsUint(0)))
        }

        // tokenURI(uint256) -> 0xc87b56dd
        case 0xc87b56dd{
          returnUint(tokenURI(decodeAsUint(0)))
        }

        // approve(address,uint256) -> 0x095ea7b3
        case 0x095ea7b3{
          approve(decodeAsAddress(0),decodeAsUint(1))
        }

        // safeTransferFrom(address,address,uint256) -> 0x42842e0e
        case 0x42842e0e{
            if iszero(_isApprovedOrOwner(caller(),decodeAsUint(2))){
                revertNotApproved()
            }
            safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), "")
        }

        // safeTransferFrom(address,address,uint256,bytes) -> 0xb88d4fde
        case 0xb88d4fde{
            if iszero(_isApprovedOrOwner(caller(),decodeAsUint(2))){
                revertNotApproved()
            }
            safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
        }

        // transferFrom(address,address,uint256) -> 0x23b872dd
        case 0x23b872dd{
            if iszero(_isApprovedOrOwner(caller(),decodeAsUint(2))){
                revertNotApproved()
            }
           
            transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
        }

        // mint(address,uint256) -> 0x40c10f19
        case 0x40c10f19{
          mint(decodeAsAddress(0), decodeAsUint(1))
        }

        // setApprovalForAll(address,bool) -> 0xa22cb465
        case 0xa22cb465{
            setApprovalForAll(caller(), decodeAsAddress(0), decodeAsUint(1))
        }

        // getApproved(uint256) -> 0x081812fc
        case 0x081812fc{
          returnUint(getApproved(decodeAsUint(0)))
        }

        // isApprovedForAll(address,address) -> 0xe985e9c5
        case 0xe985e9c5{
            returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
        }
        default { revert(0, 0) }

  // ╔══════════════════════════════════════════╗
  // ║         Decoding Helper Functions        ║
  // ╚══════════════════════════════════════════╝
      function decodeAsAddress(offset) -> v {
          /// Ensure the decoded value is a valid address
          v := decodeAsUint(offset)

          /// If the decoded value is not a valid address, revert the transaction
          if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
          }
      }

      function decodeAsUint(offset) -> v {
          /// Calculate the position of the uint in calldata
          let pos := add(4, mul(offset, 0x20))

          /// If the calldatasize is less than the position of the uint plus 0x20, revert the transaction
          if lt(calldatasize(), add(pos, 0x20)) {
              revert(0, 0)
          }

          /// Load the uint value from calldata at the calculated position
          v := calldataload(pos)
      }

  // ╔══════════════════════════════════════════╗
  // ║         Calldata Encoding Functions      ║
  // ╚══════════════════════════════════════════╝
      function returnUnit(value) -> ret{
          mstore(0x00,value)
          return(0x00, 0x20)
      }

  // ╔══════════════════════════════════════════╗
  // ║         contract main functions          ║
  // ╚══════════════════════════════════════════╝
  ///@dev Returns the total number of tokens owned by the owner
  ///@param owner address
      function balanceOf(owner) -> ret {
          if iszero(owner) {
              revertZeroAddress()
          }
          let slot := keccakHash(owner, sBalancesSlot())
          ret := sload(slot)
      }

    ///@dev Returns the address of the owner of a tokenId
        function ownerOf(tokenId) -> ret {
           let addr := getStoredValue(tokenId, sOwnersSlot())
            if iszero(addr) {
                revertZeroAddress()
            }
            ret := addr
        }

    ///@dev Mints a new token to the specified owner
    ///@param owner address
    ///@param tokenId uint
    function mint(owner, tokenId) {
            // 1. Check for zero address
            if iszero(owner) {
                revertZeroAddress()
            }
            
            // 2. Check if token already exists (FIXED _exists logic)
            let exists := _exists(tokenId)
            if exists{
                revertTokenExits()
            }
            let slotBal := keccakHash(owner, sBalancesSlot())
            let prevBal := getStoredValue(owner, sBalancesSlot())
            sstore(slotBal, add(prevBal, 0x1))//Increment Balance
            let slotOwner := keccakHash(tokenId, sOwnersSlot())
            sstore(slotOwner, owner) //Set Owner
            emitTransfer(0x0, owner, tokenId)
        }
    

    ///@dev Returns the tokenURI of a tokenId
        function tokenURI(tokenId) -> ret{
            let addr := getStoredValue(tokenId, sOwnersSlot())
            if iszero(addr) {
                revertZeroAddress()
            }
            ret := 0x0
        }

    ///@dev Approves an address to transfer a token
    ///@param to address
    ///@param tokenId to transfer
        function approve(to, tokenId){
            let owner := ownerOf(tokenId)
            if eq(owner,to){
                revertSameAddress()
            }
            if or(
                eq(caller(), owner),
                isApprovedForAll(owner, to) 
            ) {
                let approvalSlot := keccakHash(tokenId, stokenApprovalsSlot())
                sstore(approvalSlot, to)
                emitApproval(owner, to, tokenId)
                return(0,0)
            }
            revertNotApproved()
        }


    ///@notice Get the approved address for a single NFT
        function getApproved(tokenId) -> ret{
            let exists := _exists(tokenId)
            if iszero(exists){
                revertNotApproved()
            }
            ret := getStoredValue(tokenId, stokenApprovalsSlot())
        }

    ///@notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s (owner's) assets
    ///@return True if `_operator` is an approved operator for `_owner`, false otherwise
        function setApprovalForAll(owner,operator, approved){
            if iszero(operator){
                revertZeroAddress()
            }
            if eq(owner, operator){
                revertSameAddress()
            }
            // Calculate storage slot (optimized double keccak)
            let ownerApprovalsSlot := keccakHash(owner, sOperatorApprovalsSlot())
            let operatorApprovalSlot := keccakHash(operator, ownerApprovalsSlot)            
            sstore(operatorApprovalSlot, approved)
            // EmitApprovalForAll(owner, operator, approved)
            return(0,0)
        }

    ///@notice Query if an address is an authorized operator for another address
        function isApprovedForAll(owner, operator) -> ret{
            if iszero(operator){
                revertZeroAddress()
            }
            if iszero(owner){
                revertZeroAddress()
            }
            // Calculate storage slot (optimized double keccak)
            let ownerApprovalsSlot := keccakHash(owner, sOperatorApprovalsSlot())
            let operatorApprovalSlot := keccakHash(operator, ownerApprovalsSlot)

            // Load and return approval status
            ret := sload(operatorApprovalSlot)
        }

        function transferFrom(from, to, tokenId) {
            if iszero(to) {
                revertZeroAddress()
            }
            
            let owner := ownerOf(tokenId)
            if iszero(eq(owner, from)) {
                revertTransferFromIncorrectOwner()
            }
          
            let approvalSlot := keccakHash(tokenId, stokenApprovalsSlot())
            sstore(approvalSlot, 0) 
            let BalOfslotFrom := keccakHash(from, sBalancesSlot())
            let BalOfslotTo := keccakHash(to, sBalancesSlot())
            sstore(BalOfslotFrom, sub(sload(BalOfslotFrom),1)) // Decrement balance of from
            sstore(BalOfslotTo, add(sload(BalOfslotTo),1))  // Increment balance of To
            let slotOwner := keccakHash(tokenId, sOwnersSlot())
            sstore(slotOwner, to) //set new Owner
            
            emitTransfer(from, to, tokenId)
            
            return(0, 0)
        }

        function safeTransferFrom(from,to, tokenId, data){
            transferFrom(from,to, tokenId)
            let success := _checkOnERC721Received(from, to, tokenId, data)
            if iszero(success){
                mstore(0, shl(224, 0x08c379a0)) // Error selector
                mstore(4, 0x20)                  // String offset
                mstore(0x24, 0x22)               // String length
                mstore(0x44, "ERC721: transfer error")
                revert(0, 0x64)
            }

        }

        function _checkOnERC721Received(from, to, tokenId, data) -> ret {
            if iszero(extcodesize(to)) { 
                ret := 1  
                return(0,0) 
            }
        
            let memPtr := mload(0x40)
        
            // Store function selector (onERC721Received)
            mstore(memPtr, 0x150b7a02)
        
            // Store parameters
            mstore(add(memPtr, 0x04), caller())  // operator (msg.sender)
            mstore(add(memPtr, 0x24), from)      // from address
            mstore(add(memPtr, 0x44), tokenId)   // tokenId
            mstore(add(memPtr, 0x64), 0x80)      // data offset position
        
            // Because its bytes, We load the length first
            let dataLength := mload(data)
            mstore(add(memPtr, 0x84), dataLength) // data length
        
            /// For basic 32 bytes only, else you loop 
            if gt(dataLength, 0) {
                mstore(add(memPtr, 0xa4), mload(add(data, 0x20)))
            }
        
            // Make the call
            let success := call(
                gas(),to,0,memPtr,add(0xa4, dataLength),0,0x20                       
            )
        
            if success {
                // Check if return value matches expected selector
                ret := eq(mload(0), 0x150b7a02)
            }

            if iszero(success){
                mstore(0, shl(224, 0x08c379a0)) 
                mstore(4, 0x20)                  
                mstore(0x24, 0x22)               
                mstore(0x44, "ERC721: transfer Error")
                revert(0, 0x64)
            }

        }


    // ╔══════════════════════════════════════════╗
    // ║               Helpers functions          ║
    // ╚══════════════════════════════════════════╝
        function keccakHash(key1, key2) -> ret{
            mstore(0x00, key1)
            mstore(0x20, key2)
            ret := keccak256(0x00, 0x40)

        }

        function getStoredValue(key1, key2) -> value {
            mstore(0x00, key1)
            mstore(0x20, key2)
            value := sload(keccak256(0x00, 0x40))
        }
  
        function returnUint(v) {
            mstore(0, v)
            return(0, 0x20)
        }

        function _exists(tokenId) -> ret {
            let addr := getStoredValue(tokenId, sOwnersSlot())
            ret := iszero(iszero(addr)) // Returns 1 if addr != 0, 0 otherwise
        }

        function _isApprovedOrOwner(spender, tokenId) -> ret {
            let exists := _exists(tokenId)
            if iszero(exists) {
                RevertTokenDontExists()
            }
            let owner := ownerOf(tokenId)
            ret := or(
                or(
                    eq(spender, owner),
                    eq(getApproved(tokenId), spender)
                ),
                isApprovedForAll(owner, spender)
              
            )
        }

  // ╔══════════════════════════════════════════╗
  // ║               Revert functions           ║
  // ╚══════════════════════════════════════════╝

  ///@dev Reverts the transaction with a custom error and message.
  /// InvaidAdress(string) addressZero
        function revertZeroAddress() {
            mstore(0x00, 0x09a06eb600000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 0xb)
            mstore(0x44, "invalid address: addresss zero")
            revert(0x00, 0x64)
        }

    ///@dev Reverts the transaction witha custom error and message
    /// TokenExits(string)
        function revertTokenExits(){
            mstore(0x00,0x9a23482a00000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 18)
            mstore(0x44, "Token already exists")
            revert(0x00, 0x64)
        }

    ///@dev Reverts the transaction witha custom error and message
    /// RevertSameAddress(string)
        function revertSameAddress(){
            mstore(0x00, 0xedddbda700000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 0x000000000000000000000000000000000000000000000000000000000000001c)
            mstore(0x44, "same Addresses")
            revert(0x00, 0x64)
        }

    ///@dev Reverts the transaction with a custom error and a message
    /// RevertNotApproved(string)
        function revertNotApproved(){
            mstore(0x00, 0x5c910f1600000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 0x19)
            mstore(0x44, "Token not approved for transfer")
            revert(0x00, 0x64)
        }

    ///@dev Reverts the transaction with a custom error and a message
    /// RevertTransferFromIncorrectOwner(string)
        function revertTransferFromIncorrectOwner(){
            mstore(0x00, 0x1d7a7fc200000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 0x1A)
            mstore(0x44, "Transfer from incorrect owner")
            revert(0x00, 0x64)
        }
        
    ///@dev Reverts the transaction with a custom error and a message
    /// RevertTokenDontExists(string)
        function RevertTokenDontExists(){
            mstore(0x00, 0x2eb263fc00000000000000000000000000000000000000000000000000000000)
            mstore(0x04, 0x20)
            mstore(0x24, 0x12)
            mstore(0x44, "Token does not exists")
            revert(0x00, 0x64)
        }

    // ╔══════════════════════════════════════════╗
    // ║               Events functions           ║
    // ╚══════════════════════════════════════════╝

    ///@dev Emits a Transfer Event
        function emitTransfer(from, to, tokenId){
            // keccakHash of the function signature Transfer(address,address,uint256)
            let signatureHash :=  0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            mstore(0x00, from)
            log3(0x00, 0x20, signatureHash,tokenId,to)
        }
        
        ///@dev Emits an Approval Event
        function emitApproval(owner, to, tokenId){
            // keccakHash of the function signature Approval(address,address,uint256)
            let signatureHash :=  0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
            mstore(0x00, tokenId)
            log3(0x00, 0x20, signatureHash,owner,to)
        }
        }

        ///@dev Emits an ApprovalForAll Event
        // function EmitApprovalForAll(owner, operator,approved){
        //     // keccakHash of the function signature ApprovalForAll(address,address,bool)
        //     let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        //     mstore(0x00, owner)
        //     log3(0x00, 0x20,signatureHash, operator, approved)
        // }
    }
    }

