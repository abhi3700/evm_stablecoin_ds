import { ethers } from "hardhat";

import { shouldBehaveLikeOwnable } from "./behaviors/Ownable.behavior";
import { shouldBehaveLikePausable } from "./behaviors/Pausable.behavior";
import { deployDiamondTest } from "../../deployment/diamond.utils";
import { ONE_WEEK, parseWithDecimals } from "../helper";
import { Contract, ContractFactory } from "ethers";

export function likeBorrowerOperations(): void {
  describe("===BorrowerOperations SC===", function () {
    beforeEach(async () => {
      this.ctx.signers = await ethers.getSigners();
      const [owner, alice, bob, eve] = this.ctx.signers;
      // this.ctx.treasury = this.ctx.signers[9];

      // Deploy MojoCustomBase Contract
      const MojoCustomBaseFactory: ContractFactory =
        await ethers.getContractFactory("MojoCustomBase");
      const mojoCustomBase: Contract = await MojoCustomBaseFactory.deploy();
      await mojoCustomBase.deployed();
      this.ctx.mojoCustomBase = mojoCustomBase;

      /// Deploy Mojo Diamond
      this.ctx.mojodiamond = await deployDiamondTest(
        mojoCustomBase.address,
        ethers
      );
      // Set Facet Addresses
      this.ctx.diamondLoupeFacet = await ethers.getContractAt(
        "DiamondLoupeFacet",
        this.ctx.mojodiamond.address
      );
      this.ctx.ownershipFacet = await ethers.getContractAt(
        "OwnershipFacet",
        this.ctx.mojodiamond.address
      );
      this.ctx.pausableFacet = await ethers.getContractAt(
        "PausableFacet",
        this.ctx.mojodiamond.address
      );
      this.ctx.ActivePoolFacet = await ethers.getContractAt(
        "ActivePool",
        this.ctx.mojodiamond.address
      );
      this.ctx.ActivePoolFacet = await ethers.getContractAt(
        "DefaultPool",
        this.ctx.mojodiamond.address
      );
      this.ctx.whitelistFacet = await ethers.getContractAt(
        "Whitelist",
        this.ctx.mojodiamond.address
      );
    });

    shouldBehaveLikeOwnable();

    shouldBehaveLikePausable();
  });
}
