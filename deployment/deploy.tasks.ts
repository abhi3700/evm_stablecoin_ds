import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import { deployDiamond } from "./diamond.utils";
import { Contract, ContractFactory } from "ethers";

export const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

// ========deploy MojoCustomBase=============
task("deploy:MojoCustomBase", "Deploy MojoCustomBase Contract").setAction(
  async function (taskArguments: TaskArguments, { ethers }) {
    const MojoCustomBaseFactory: ContractFactory =
      await ethers.getContractFactory("MojoCustomBase");
    const mojoCustomBase: Contract = await MojoCustomBaseFactory.deploy();
    await mojoCustomBase.deployed();

    console.log("MojoCustomBase deployed to:", mojoCustomBase.address);
  }
);

// ========deploy USM SC=============
task("deploy:USM", "Deploy USM Contract").setAction(async function (
  taskArguments: TaskArguments,
  { ethers }
) {
  const StableCoinFactory: ContractFactory = await ethers.getContractFactory(
    "StableCoin"
  );
  const stableCoin: Contract = await StableCoinFactory.deploy(
    "Polygon Native Stablecoin",
    "USM",
    ethers.utils.parseUnits((1000_000_000_000).toString(), 18)
  );
  await stableCoin.deployed();

  console.log("USM deployed to:", stableCoin.address);
});

// ========deploy Facets=============
// deploy only facets
task("deploy:Facets", "Deploy the all facet contracts").setAction(
  async function (taskArgs: TaskArguments, { ethers }) {
    // deploy facets
    const FacetNames = [
      "DiamondLoupeFacet",
      "OwnershipFacet",
      "PausableFacet",
      "ActivePool",
      "DefaultPool",
      "Whitelist",
      // "BorrowerOperations",
    ];

    for (const FacetName of FacetNames) {
      const Facet: ContractFactory = await ethers.getContractFactory(FacetName);
      const facet: Contract = await Facet.deploy();
      await facet.deployed();
      console.log(`${FacetName} deployed: ${facet.address}`);
    }
  }
);

// ################# All steps #####################
task("deploy:LaunchMojo", "All steps for deploying and launching Mojo")
  // define params as string, number (used in constructor)
  .addParam("mojocustombaseaddr", "The stable coin's address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    // 1. Deploy Diamond with all facets
    // console.log("diamond deployment initiated...");
    deployDiamond(taskArguments.mojocustombaseaddr, ethers);
    // console.log("diamond deployed");

    // Deploy USM coin

    // 2. setAddresses for all the state variables in Diamond lib

    // 3. Add collateral asset as whitelist
  });
