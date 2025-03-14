# Butter Finance Foundry

## Overview
Our contracts module would be an DeFi yield aggregator that helps users stake rewards across multiple protocols as below:
![Module_Architecure](/public/module_architecture.png)




## Core Features
To keep it simple, we developed 4 mock staking protocols with same logic allowing users stake WMOD and earn sWMOD, based on the period and amount they deposit. The four staking protocols only differences in function names (to simulate different protocols in the market) and the reward rate.
our backend will monitor the pool state and reward rate to calculate APR of each protocol and store the info into our DB. When user wants to get a recommendation by APR, our LLM agent will reference to the DB and recommend the top-k highest APR to users.

## Technical Stack
- Smart Contracts: Solidity + Foundry
- Test Network: Monad Testnet
- Tokens: WMOD (stake) & sWMOD (reward). Note that the WMOD and sWMOD here are mocked and launched by us on Testnet. We assumed that 1 sWMOD can be exchanged back to 1 WMOD in our system.

## Contract Addresses on Monad Testnet
```
WMOD: 0x026BA669dA22b19A0332a735CD924D5ec4D3a99E
sWMOD: 0x4fb8181903E9D0034bbA4B1Dca3a282335E84978
Aggregator: 0x12C61b22b397a6D72AD85f699fAf2D75f50D556C
SimpleStake: 0x81E0A65478Ca0BE79F972135a6Aa1415d5C6e95d
HappyStake: 0x1Effd0f1bc233489111E83654b59a8060b3524c3
EasyStake: 0x0303DeED11eDE0716F223523aa8049e2021FD852
CakeStake: 0xfAF32EeBA6504fE90d2c7039117A21AED9D40D2B
SimpleStakeAdapter: 0x8dB16e83ae92425c3074562fDddFF62B3FBCa71d
HappyStakeAdapter: 0x4a7A418E5AA6a974602e61B62444D68cf4212102
EasyStakeAdapter: 0xeB85FE4e3df41bafeb480BE14cCFC9F1fdd81787
CakeStakeAdapter: 0x267912C677b2e51362aE97e024eBD4f41d920180
```
