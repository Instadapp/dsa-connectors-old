# DSA Connectors

Connectors are standard modules that let DeFi Smart Account interact with various smart contracts, and make the important actions accessible like cross protocol interoperability.

## Add Custom Connectors

1. Fork and clone it
2. Create a feature branch: `git checkout -b new-connector`
3. Add the connector solidity file to `contracts/connectors`
4. Commit changes: `git commit -am 'Added a connector'`
5. Push to the remote branch: `git push origin new-connector`
6. Create a new Pull Request.

## Requirements

Be sure to comply with the requirements while building connectors for better compatibility.

- Import common files from `contracts/common` directory.
- The contracts should not have `selfdestruct()`.
- The contracts should not have `delegatecall()`.
- Use `uint(-1)` for maximum amount everywhere.
- Use `getEthAddr()` to denote Ethereum (non-ERC20).
- Use `address(this)` instead of `msg.sender` for fetching balance on-chain, etc.
- Only `approve()` limited amount while giving ERC20 allowance, which strictly needs to be 0 by the end of the spell.
- Use `getId()` for getting value that saved from previous spell.
- Use `setId()` for setting value to save for the future spell.

<!-- - If required, Add two additional parameter, `getId` & `setId` in external public functions.
- Use `getUint()` or `setUint()` functions to fetch or store values.
- Call `emitEvent()` after every external public functions. -->

<!-- Be sure to check [this mock file](https://github.com/InstaDApp/dsa-connectors/blob/master/contracts/connectors/mock.sol) for reference. -->

## Support

If you can't find something you're looking for or have any questions, ask them at our developers community on [Telegram](https://t.me/instadevelopers), [Discord](https://discord.gg/83vvrnY) or simply send an [Email](mailto:info@instadapp.io).
