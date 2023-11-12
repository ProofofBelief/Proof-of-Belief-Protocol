import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  // async function deployOneYearLockFixture() {
  //   const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //   const ONE_GWEI = 1_000_000_000;

  //   const lockedAmount = ONE_GWEI;
  //   const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

  //   // Contracts are deployed using the first signer/account by default
  //   const [owner, otherAccount] = await ethers.getSigners();

  //   const Lock = await ethers.getContractFactory("Lock");
  //   const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  //   return { lock, unlockTime, lockedAmount, owner, otherAccount };
  // }

  async function deployFixture() {
    const Lock = await ethers.getContractFactory("Lock");
    const lock = await Lock.deploy();
    const lockAddress = await lock.getAddress();

    const TestToken = await ethers.getContractFactory("TestToken");
    const parentCollection = await TestToken.deploy();
    const parentCollectionAddress = await parentCollection.getAddress();

    const PoBNFT = await ethers.getContractFactory("PoBNFT");
    const childCollection = await PoBNFT.deploy(lockAddress, parentCollectionAddress);
    const childCollectionAddress = await childCollection.getAddress();

    const [user, otherUser] = await ethers.getSigners();

    const lockTokenIds = ['0'];
    for (const tokenId of lockTokenIds) {
      await parentCollection.mint(user.address, tokenId, { from: user.address });
      await parentCollection.approve(lockAddress, tokenId, { from: user.address });
    }

    return {
      lock,
      lockAddress,
      parentCollection,
      childCollection,
      parentCollectionAddress,
      childCollectionAddress,
      user,
      otherUser,
      lockTokenIds,
    }
  }

  describe('lockNFT', function () {
    it('lock', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await expect(
        lock.lockNFT(
          childCollectionAddress,
          parentCollectionAddress, 
          lockTokenIds, 
        )
      ).to.emit(lock, 'NFTLocked').withArgs(
        user.address,
        parentCollectionAddress,
        childCollectionAddress,
        lockTokenIds,
        await time.latest() + 1,
      );

      expect(await parentCollection.ownerOf('0')).to.equal(lockAddress);
    });
  });

  describe('unlockNFT', function () {
    it('validate owner', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        otherUser,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await expect(lock.connect(otherUser).unlockNFT(
        parentCollection,
        lockTokenIds,
      )).to.be.revertedWith('Only owner can unlock');
    });

    it('unlock', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        otherUser,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await lock.lockNFT(
        childCollectionAddress,
        parentCollectionAddress, 
        lockTokenIds, 
      )

      expect(await lock.unlockNFT(
        parentCollection,
        lockTokenIds,
      )).to.emit(lock, 'NFTUnlocked').withArgs(
        user.address,
        parentCollectionAddress,
        lockTokenIds,
      );

      expect(await parentCollection.ownerOf('0')).to.equal(user.address);
    });
  });

  describe('releaseNFT', function () {
    it('validate target collection', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        otherUser,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await lock.lockNFT(
        childCollectionAddress,
        parentCollectionAddress, 
        lockTokenIds,
      );

      await time.increase(60);
      const childTokenId = '10000';

      await expect(
        lock.connect(otherUser).releaseNFT(
          parentCollection,
          lockTokenIds,
          60,
        )
      ).to.be.revertedWith('Only target collection can release');
    });

    it('validate lock duraion', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        otherUser,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await lock.lockNFT(
        childCollectionAddress,
        parentCollectionAddress, 
        lockTokenIds, 
      );

      const childTokenId = '10000';

      // mint child collection, reverted
      await expect(
        childCollection.mint(lockTokenIds, "belief")
      ).to.be.revertedWith('Lock duration not met');
    });

    it('release', async () => {
      const {
        lock,
        lockAddress,
        parentCollection,
        childCollection,
        parentCollectionAddress,
        childCollectionAddress,
        user,
        otherUser,
        lockTokenIds,
      } = await loadFixture(deployFixture);

      await lock.lockNFT(
        childCollectionAddress,
        parentCollectionAddress, 
        lockTokenIds, 
      );

      expect(await childCollection.getNextRequiredLockDuration(1)).to.equal(600);
      expect(await childCollection.getNextRequiredLockDuration(10)).to.equal(60);

      await time.increase(600);
      await childCollection.mint(lockTokenIds, "belief");
      expect(await childCollection.ownerOf('1')).to.equal(user.address);
      expect(await childCollection.tokenURI('1')).to.equal('data:text/plain;base64,YmVsaWVm');

      expect(await childCollection.getNextRequiredLockDuration(1)).to.equal(1200);
    });
  });
  // describe("Deployment", function () {
  //   it("Should set the right unlockTime", async function () {
  //     const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

  //     expect(await lock.unlockTime()).to.equal(unlockTime);
  //   });

  //   it("Should set the right owner", async function () {
  //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);

  //     expect(await lock.owner()).to.equal(owner.address);
  //   });

  //   it("Should receive and store the funds to lock", async function () {
  //     const { lock, lockedAmount } = await loadFixture(
  //       deployOneYearLockFixture
  //     );

  //     expect(await ethers.provider.getBalance(lock.target)).to.equal(
  //       lockedAmount
  //     );
  //   });

  //   it("Should fail if the unlockTime is not in the future", async function () {
  //     // We don't use the fixture here because we want a different deployment
  //     const latestTime = await time.latest();
  //     const Lock = await ethers.getContractFactory("Lock");
  //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
  //       "Unlock time should be in the future"
  //     );
  //   });
  // });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
