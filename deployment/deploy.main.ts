import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import {
  activePoolAddress,
  defaultPoolAddress,
  whitelistAddress,
  deployDiamond,
} from "./diamond.utils";
// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function main(): Promise<void> {
  console.log(`---1---`);
  // ==== 1. Deploy 'MojoCustomBase' contract
  const MojoCustomBaseFactory: ContractFactory =
    await ethers.getContractFactory("MojoCustomBase");
  const mojoCustomBase: Contract = await MojoCustomBaseFactory.deploy();
  await mojoCustomBase.deployed();

  console.log(`MojoCustomBase deployed to: ${mojoCustomBase.address}`);
  // ==== (2, 3): call `deployDiamond` function to deploy facets, diamond
  const diamond: Contract = await deployDiamond(
    mojoCustomBase.address,
    ethers
  ).then((result) => result);
  console.log(`---4---`);
  // ==== 4. set addresses of the facets via `setAddresses()` function
  // const owner: SignerWithAddress = await ethers.utils
  //   .getAddress(cut[1].facetAddress)
  //   .owner();
  // TODO: add all the addresses
  const txn1 = await diamond.setAddresses(
    activePoolAddress,
    defaultPoolAddress,
    whitelistAddress
  );
  const receipt1 = await txn1.wait();
  console.log(
    `Owner set addresses & its transaction hash:
    ${receipt1.transactionHash}`
  );
  // console.log(`---5---`);
  // ==== 5. add collateral assets as whitelist
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then()
  .catch((error: Error) => {
    console.error(error);
    throw new Error("Exit: 1");
  });
