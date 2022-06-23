import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

export function shouldBehaveLikeOwnable(): void {
  describe("1. Ownable", async function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let ownershipFacet: Contract;

    beforeEach(async () => {
      [owner, alice, bob] = this.ctx.signers;
      ownershipFacet = this.ctx.ownershipFacet;
    });

    it("1.1 Protocol contract`s owner will be deployer", async () => {
      expect(await ownershipFacet.owner()).to.be.eq(owner.address);
    });

    it("1.2 Succeeds when owner transfers ownership", async () => {
      await expect(
        ownershipFacet.connect(owner).transferOwnership(alice.address)
      ).to.emit(ownershipFacet, "OwnershipTransferred");
    });

    it("1.3 Fails when non-owner transfers ownership", async () => {
      await expect(
        ownershipFacet.connect(alice).transferOwnership(bob.address)
      ).to.be.revertedWith("LIBE0");
    });
  });
}
