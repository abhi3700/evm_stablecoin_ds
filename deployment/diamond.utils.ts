/* 
  Deploy Diamond Utility
*/
import { HardhatEthersHelpers } from "@nomiclabs/hardhat-ethers/types";
import { /* BigNumber, */ Contract, ContractFactory } from "ethers";
import { ZERO_ADDRESS, FacetCutAction, getSelectors } from "../libs/diamond";

export let activePoolAddress: any;
export let defaultPoolAddress: any;
export let whitelistAddress: any;

export async function deployDiamond(
  mojoCustomBaseAddr: string,
  ethers: HardhatEthersHelpers
  // define params as string, number (used in constructor)
) {
  console.log(`---2---`);
  // ==== 1. deploy facets
  console.log("Deploying facets:");
  const FacetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "PausableFacet",
    "ActivePool",
    "DefaultPool",
    "Whitelist",
    // "BorrowerOperations",
  ];
  const cut = [];

  for (const FacetName of FacetNames) {
    // console.log(`${FacetName}`);
    const Facet: ContractFactory = await ethers.getContractFactory(FacetName);
    // console.log("2");
    const facet: Contract = await Facet.deploy();
    // console.log("3");
    await facet.deployed();
    console.log(`${FacetName} deployed: ${facet.address}`);

    // eslint-disable-next-line eqeqeq
    if (FacetName == "ActivePool") {
      activePoolAddress = facet.address;
      // eslint-disable-next-line eqeqeq
    } else if (FacetName == "DefaultPool") {
      defaultPoolAddress = facet.address;
      // eslint-disable-next-line eqeqeq
    } else if (FacetName == "Whitelist") {
      whitelistAddress = facet.address;
    }
    // when deploying MojoDiamond, FacetCutAction should be "Add"
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet).signatures,
    });
  }

  console.log(`---3---`);
  // ==== 2. deploy Diamond
  const Diamond: ContractFactory = await ethers.getContractFactory(
    "MojoDiamond"
  );
  const diamond: Contract = await Diamond.deploy(mojoCustomBaseAddr, cut);
  await diamond.deployed();
  console.log(
    `MojoDiamond deployed: ${diamond.address} at transaction hash: ${diamond.deployTransaction.hash}`
  );

  // return diamond.address;
  return diamond;
}

// duplicate of `deployDiamond()` without `console.log`
export async function deployDiamondTest(
  mojoCustomBaseAddr: string,
  ethers: HardhatEthersHelpers
  // define params as string, number (used in constructor)
) {
  // console.log(`---2---`);
  // ==== 1. deploy facets
  // console.log("Deploying facets:");
  const FacetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "PausableFacet",
    "ActivePool",
    "DefaultPool",
    "Whitelist",
    // "BorrowerOperations",
  ];
  const cut = [];

  for (const FacetName of FacetNames) {
    // console.log(`${FacetName}`);
    const Facet: ContractFactory = await ethers.getContractFactory(FacetName);
    // console.log("2");
    const facet: Contract = await Facet.deploy();
    // console.log("3");
    await facet.deployed();
    // console.log(`${FacetName} deployed: ${facet.address}`);

    // eslint-disable-next-line eqeqeq
    if (FacetName == "ActivePool") {
      activePoolAddress = facet.address;
      // eslint-disable-next-line eqeqeq
    } else if (FacetName == "DefaultPool") {
      defaultPoolAddress = facet.address;
      // eslint-disable-next-line eqeqeq
    } else if (FacetName == "Whitelist") {
      whitelistAddress = facet.address;
    }
    // when deploying MojoDiamond, FacetCutAction should be "Add"
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet).signatures,
    });
  }

  // console.log(`---3---`);
  // ==== 2. deploy Diamond
  const Diamond: ContractFactory = await ethers.getContractFactory(
    "MojoDiamond"
  );
  const diamond: Contract = await Diamond.deploy(mojoCustomBaseAddr, cut);
  await diamond.deployed();
  // console.log(
  //   `MojoDiamond deployed: ${diamond.address} at transaction hash: ${diamond.deployTransaction.hash}`
  // );

  // return diamond.address;
  return diamond;
}

export async function addFuncsDiamond(
  ethers: HardhatEthersHelpers,
  mojoaddr: string,
  newFacetName: string,
  funcName = null
) {
  const diamond: Contract = await ethers.getContractAt("MojoDiamond", mojoaddr);

  // deploy facets
  console.log("Add Function to deployed Mojo Diamond");

  const Facet: ContractFactory = await ethers.getContractFactory(newFacetName);
  const facet: Contract = await Facet.deploy();
  await facet.deployed();
  console.log(`Deployed New Facet : ${mojoaddr}`);

  const selectors = funcName
    ? getSelectors(facet).get([funcName]).signatures
    : getSelectors(facet).signatures;
  const cut = [
    {
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: selectors,
    },
  ];

  // upgrade diamond with facets
  console.log("Diamond Cut:", cut);

  // TODO if you need to initialize state variable after adding, you can use InitDiamond same as the following

  // // deploy InitDiamond
  // // InitDiamond provides a function that is called when the diamond is upgraded to initialize state variables
  // // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions

  // const InitDiamond: ContractFactory = await ethers.getContractFactory(
  //     "InitDiamond"
  // );
  // const diamondInit: Contract = await InitDiamond.deploy();
  // await diamondInit.deployed();
  // console.log("InitDiamond deployed:", diamondInit.address);

  // // call to init function
  // const functionCall = diamondInit.interface.encodeFunctionData("init");
  // const tx = await diamond.diamondCut(cut, diamondInit.address, functionCall);
  //
  // const receipt = await tx.wait();
  // if (!receipt.status) {
  //   throw Error(`Diamond update failed: ${tx.hash}`);
  // }

  const tx = await diamond.diamondCut(cut, ZERO_ADDRESS, "0x");
  // console.log('Diamond cut tx: ', tx.hash)
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  // console.log('Completed diamond cut')

  return diamond.address;
}

export async function updateFuncsDiamond(
  ethers: HardhatEthersHelpers,
  mojoaddr: string,
  newFacetName: string,
  funcName = null
) {
  const diamond: Contract = await ethers.getContractAt("MojoDiamond", mojoaddr);

  // deploy facets
  console.log("Add Function to deployed Mojo Diamond");

  const Facet: ContractFactory = await ethers.getContractFactory(newFacetName);
  const facet: Contract = await Facet.deploy();
  await facet.deployed();
  console.log(`Deployed New Facet : ${mojoaddr}`);

  const selectors = funcName
    ? getSelectors(facet).get([funcName]).signatures
    : getSelectors(facet).signatures;
  const cut = [
    {
      facetAddress: facet.address,
      action: FacetCutAction.Replace,
      functionSelectors: selectors,
    },
  ];

  // upgrade diamond with facets
  console.log("Diamond Cut:", cut);

  const tx = await diamond.diamondCut(cut, ZERO_ADDRESS, "0x");
  // console.log('Diamond cut tx: ', tx.hash)
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  // console.log('Completed diamond cut')

  return diamond.address;
}

export async function removeFuncsDiamond(
  ethers: HardhatEthersHelpers,
  mojoaddr: string,
  facetAddr: string
) {
  const diamond: Contract = await ethers.getContractAt("MojoDiamond", mojoaddr);

  // deploy facets
  console.log("Remove Functions to deployed Mojo Diamond");

  const diamondLoupeFacet: Contract = await ethers.getContractAt(
    "DiamondLoupeFacet",
    mojoaddr
  );
  const selectors = await diamondLoupeFacet.facetFunctionSelectors(facetAddr);

  const cut = [
    {
      facetAddress: ZERO_ADDRESS,
      action: FacetCutAction.Remove,
      functionSelectors: selectors,
    },
  ];

  // upgrade diamond with facets
  console.log("Diamond Cut:", cut);

  const tx = await diamond.diamondCut(cut, ZERO_ADDRESS, "0x");
  // console.log('Diamond cut tx: ', tx.hash)
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  // console.log('Completed diamond cut')

  return diamond.address;
}
