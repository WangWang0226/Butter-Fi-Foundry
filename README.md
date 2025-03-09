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

