import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import {
  addFuncsDiamond,
  removeFuncsDiamond,
  updateFuncsDiamond,
} from "./diamond.utils";

task("upgrade:AddFunction", "Update Mojo")
  .addParam("mojoaddr", "Deployed Mojo Diamond Address")
  .addParam("facetname", "Deployed New Diamond Facet Name")
  .addParam("funcname", "UpdateFunctionName")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    /// Deploy Mojo
    await addFuncsDiamond(
      ethers,
      taskArguments.mojoaddr,
      taskArguments.facetname,
      taskArguments.funcname
    );
    console.log(
      `${taskArguments.facetname}(${taskArguments.funcname}) was added`
    );
  });

task("upgrade:UpdateFunction", "Update Mojo")
  .addParam("mojoaddr", "Deployed Mojo Diamond Address")
  .addParam("facetname", "Deployed New Diamond Facet Name")
  .addParam("funcname", "UpdateFunctionName")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    /// Deploy Mojo
    updateFuncsDiamond(
      ethers,
      taskArguments.mojoaddr,
      taskArguments.facetname,
      taskArguments.funcname
    );
    console.log(
      `${taskArguments.facetname}(${taskArguments.funcname}) was updated`
    );
  });

task("upgrade:AddFacet", "Update Mojo")
  .addParam("mojoaddr", "Deployed Mojo Diamond Address")
  .addParam("facetname", "Deployed New Diamond Facet Name")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    /// Deploy Mojo
    await addFuncsDiamond(
      ethers,
      taskArguments.mojoaddr,
      taskArguments.facetname
    );
    console.log(`${taskArguments.facetname} was added`);
  });

task("upgrade:UpdateFacet", "Update Mojo")
  .addParam("mojoaddr", "Deployed Mojo Diamond Address")
  .addParam("facetname", "Deployed New Diamond Facet Name")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    /// Deploy Mojo
    await updateFuncsDiamond(
      ethers,
      taskArguments.mojoaddr,
      taskArguments.facetname
    );
    console.log(`${taskArguments.facetname} was updated`);
  });

task("upgrade:RemoveFacet", "Update Mojo")
  .addParam("mojoaddr", "Deployed Mojo Diamond Address")
  .addParam("facetaddr", "Deployed New Diamond Facet Address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    /// Deploy Mojo
    await removeFuncsDiamond(
      ethers,
      taskArguments.mojoaddr,
      taskArguments.facetaddr
    );
    console.log(`Facet(${taskArguments.facetaddr}) was removed`);
  });
