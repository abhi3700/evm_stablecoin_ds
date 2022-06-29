# FAQ

Here, the FAQs are smart contract centric.

#### Q1. Why SC is designed based on Diamond Standard rather than other proxy patterns?

#### A1
It is the most robust architecture out of all proxy patterns existing in the EVM upgradeable SC ecosystem. The following are the reasons:

- **Upgradeability**: The SC can be upgraded both in terms of state variables & code logic.
- **No size limit**: It would never hit the contract size limit because of its capability of integrating unlimited facets to the Diamond proxy contract.
- **Lightweight**: Normally, there are functions & storage variables maintained in some of the main contracts like in case of DeFi pools. But, here all the unique storage variables are maintained at one position inside Diamond proxy contract & the code logic is available in the attached facets.
- **Modular**: In case of big codebase where the upgradeability is a requirement, it is important to have a design where a facet can be linked/delinked because of unneeded features.

Read [more](https://eip2535diamonds.substack.com/p/answering-some-diamond-questions)

#### Q2. Why Hardhat as testing framework?

#### A2

- It provides stack of errors, which helps in debugging the error.
- It provides built-in console log feature.
- The developer community is very big to support with required utility packages other than the mandatory ones.
