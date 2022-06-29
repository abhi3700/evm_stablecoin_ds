import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

export function shouldBehaveLikePausable(): void {
  describe("2. Pausable", async function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let pausableFacet: Contract;

    beforeEach(async () => {
      [owner, alice] = this.ctx.signers;
      pausableFacet = this.ctx.pausableFacet;
    });

    it("2.1 Succeeds if owner pause when NOT paused", async () => {
      await expect(pausableFacet.pause())
        .to.emit(pausableFacet, "Paused")
        .withArgs(owner.address);
      expect(await pausableFacet.paused()).to.be.eq(true);
    });

    it("2.2 Succeeds if owner unpause when already paused", async () => {
      await pausableFacet.pause();

      await expect(pausableFacet.unpause())
        .to.emit(pausableFacet, "Unpaused")
        .withArgs(owner.address);

      expect(await pausableFacet.paused()).to.be.eq(false);
    });

    it("2.3 Fails if owner pause when already paused", async () => {
      await pausableFacet.pause();

      await expect(pausableFacet.pause()).to.be.revertedWith("LIBE2");
    });

    it("2.4 Fails if owner unpause when already unpaused", async () => {
      await pausableFacet.pause();

      await pausableFacet.unpause();

      await expect(pausableFacet.unpause()).to.be.revertedWith("LIBE1");
    });

    it("2.5 Fails if non-owner pause when NOT paused", async () => {
      await expect(pausableFacet.connect(alice).pause()).to.be.revertedWith(
        "LIBE0"
      );
    });

    it("2.6 Fails if non-owner unpause when already paused", async () => {
      await pausableFacet.pause();

      await expect(pausableFacet.connect(alice).unpause()).to.be.revertedWith(
        "LIBE0"
      );
    });
  });
}
