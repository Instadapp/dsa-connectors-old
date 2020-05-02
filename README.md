# DeFi Smart Account Connectors

Connectors are standardized modules that let Smart Account interact with various smart contracts, and make the important actions accessible to smart accounts.

## Add Custom Connectors

1. Fork and clone it
2. Create a feature branch: `git checkout -b new-connector`
3. Commit changes: `git commit -am 'Added a connector'`
4. Push to the remote branch: `git push origin new-connector`
5. Create a new [Pull Request](https://github.com/InstaDApp/dsa-connectors/pull/new/master)

## Requirements

- The contracts should not have `selfdestruct()`.
- The contracts should not have `delegatecall()`.
- Use `uint(-1)` for maximum amount everywhere.
- Import files from common directory.
- If needed, add `getId` & `setId`, two additional parameter for external public facing functions to fetch or store values.
- Use `getUint()` or `setUint()` functions to fetch or store values.
- Call `emitEvent()` after every external public facing functions to follow a common event standard for better analytics.

## Support

If you can't find something you're looking for or have any questions, ask them at our developers community on [Telegram](https://t.me/instadevelopers), [Discord](https://discord.gg/83vvrnY) or simply send an [Email](mailto:info@instadapp.io).