const {expect, assert} = require("chai")

const {initEthers, assertThrowsMessage, signPackedData, getTimestamp, increaseBlockTimestampBy} = require('./helpers')

describe("SynNFTFactory", function () {

  let SynNFT
  let synNft
  let SynNFTFactory
  let synFactory
  let nftId
  let price
  let conf
  let maxAllocation

  let addr0 = '0x0000000000000000000000000000000000000000'
  let owner,
      treasury,
      validator,
      buyer1, buyer2,
      communityMenber1, communityMenber2,
      collector1, collector2

  before(async function () {
    ;[
      owner,
      treasury,
      buyer1, buyer2,
      validator,
      communityMenber1, communityMenber2,
      collector1, collector2
    ] = await ethers.getSigners()
    nftId = ethers.utils.id('SBP')
    price = ethers.BigNumber.from('1'+'0'.repeat(17)) // 0.1 ETH
    maxAllocation = ethers.BigNumber.from(3)
    initEthers(ethers)
  })

  async function initAndDeploy() {
      SynNFT = await ethers.getContractFactory("SynNFT")
      synNft = await SynNFT.deploy('Blueprints', 'SBP', 'https://syn.io/meta/', 1000)
      await synNft.deployed()
      SynNFTFactory = await ethers.getContractFactory("SynNFTFactory")
      synFactory = await SynNFTFactory.deploy(validator.address, treasury.address)
      await synFactory.deployed()
      synNft.setFactory(synFactory.address)
  }

  async function configure() {
    await synFactory.init(
        synNft.address,
        price,
        maxAllocation
    )
  }

  describe('constructor and initialization', async function () {

    beforeEach(async function () {
      await initAndDeploy()
    })


    it("should return the SynNFT address", async function () {
      expect(await synFactory.validator()).to.equal(validator.address)
    })

    it("should initialize the factory", async function () {
      await configure()
      const conf = await synFactory.getNftConf(nftId)
      assert.equal(conf.nft, synNft.address)
      assert.equal(conf.price.toString(), price.toString())
      assert.equal(conf.maxAllocation.toString(), maxAllocation.toString())
      assert.equal(conf.started, false)
      assert.equal(conf.paused, false)
    })

  })

  describe('sale not started or paused', async function () {

    beforeEach(async function () {
      await initAndDeploy()
      await configure()
    })

    it("should throw if sale not started yet", async function () {

      assertThrowsMessage(
          synFactory.buyTokens(nftId, 3, {
            value: price.mul(3)
          }),
          'public sale not started yet')

    })

    it("should throw if sale started but is currently paused in the meantime", async function () {

      await synFactory.startAndPauseUnpauseSale(nftId, true)

      const conf = await synFactory.getNftConf(nftId)
      assert.equal(conf.paused, true)

      assertThrowsMessage(
          synFactory.buyTokens(nftId, 3, {
            value: price.mul(3)
          }),
          'public sale has been paused')
    })

  })

  describe('#buyTokens', async function () {

    beforeEach(async function () {
      await initAndDeploy()
      await configure()
      await synFactory.startAndPauseUnpauseSale(nftId, false)
      const conf = await synFactory.getNftConf(nftId)
      assert.equal(conf.started, true)
      assert.equal(conf.paused, false)
    })

    it("should buyer1 mint 3 tokens if sale started", async function () {

      // start the sale:
      // await increaseBlockTimestampBy(3601)

      await expect(await synFactory.connect(buyer1).buyTokens(nftId, 3, {
        value: price.mul(3)
      }))
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, buyer1.address, 1)
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, buyer1.address, 2)
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, buyer1.address, 3)

    })

    it("should throw if buyer1 try to mint 3 tokens with bad balance", async function () {

      // start the sale:
      // await increaseBlockTimestampBy(3601)

      await assertThrowsMessage(synFactory.connect(buyer1).buyTokens(nftId, 3, {
        value: price
      }), 'insufficient payment')

    })

  })

  describe('#claimFreeTokens', async function () {

    let tokens1
    let tokens2

    beforeEach(async function () {
      await initAndDeploy()
      await configure()
      await synFactory.startAndPauseUnpauseSale(nftId, false)
      const conf = await synFactory.getNftConf(nftId)
    })

    it("should communityMenber1 mint 2 tokens", async function () {

      const quantity = 2
      const authCode = ethers.utils.id('a'+ Math.random())

      const hash = await synFactory['encodeForSignature(address,bytes32,uint256,bytes32)'](communityMenber1.address, nftId, quantity, authCode)
      const signature = await signPackedData(hash)

      expect(await synFactory.connect(communityMenber1).claimFreeTokens(nftId, quantity, authCode, signature))
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, communityMenber1.address, 1)
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, communityMenber1.address, 2)

    })

    it("should throw calling from the wrong address", async function () {

      const quantity = 2
      const authCode = ethers.utils.id('a'+ Math.random())

      const hash = await synFactory['encodeForSignature(address,bytes32,uint256,bytes32)'](communityMenber1.address, nftId, quantity, authCode)
      const signature = await signPackedData(hash)

      await assertThrowsMessage(synFactory.connect(communityMenber2).claimFreeTokens(nftId, quantity, authCode, signature), 'invalid signature')

    })

  })

  describe('#buyDiscountedTokens', async function () {

    let tokens1
    let tokens2

    beforeEach(async function () {
      await initAndDeploy()
      await configure()
      await synFactory.startAndPauseUnpauseSale(nftId, false)
      const conf = await synFactory.getNftConf(nftId)
    })

    it("should buyer1 mint 1 token", async function () {

      const quantity = 1
      const authCode = ethers.utils.id('a'+ Math.random())
      const discountedPrice = price.div(100).mul(90)

      const hash = await synFactory['encodeForSignature(address,bytes32,uint256,bytes32,uint256)'](buyer1.address, nftId, quantity, authCode, discountedPrice)
      const signature = await signPackedData(hash)

      expect(await synFactory.connect(buyer1).buyDiscountedTokens(nftId, quantity, authCode, discountedPrice, signature, {
        value: discountedPrice
      }))
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, buyer1.address, 1)

    })

    it("should throw trying to reuse same code/signature", async function () {

      const quantity = 1
      const authCode = ethers.utils.id('a'+ Math.random())
      const discountedPrice = price.div(100).mul(90)

      const hash = await synFactory['encodeForSignature(address,bytes32,uint256,bytes32,uint256)'](buyer1.address, nftId, quantity, authCode, discountedPrice)
      const signature = await signPackedData(hash)

      expect(await synFactory.connect(buyer1).buyDiscountedTokens(nftId, quantity, authCode, discountedPrice, signature, {
        value: discountedPrice
      }))
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, buyer1.address, 1)

      await assertThrowsMessage(synFactory.connect(buyer1).buyDiscountedTokens(nftId, quantity, authCode, discountedPrice, signature, {
        value: discountedPrice
      }), 'authCode already used')

    })

  })

  describe('#giveawayTokens', async function () {

    beforeEach(async function () {
      await initAndDeploy()
      await configure()
    })

    it("should owner giveaway 2 tokens to collector1 and 1 to collector 2", async function () {

      const recipients = [communityMenber1.address, communityMenber2.address]
      const quantities = [2, 1]

      await expect(await synFactory.giveawayTokens(nftId, recipients, quantities))
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, communityMenber1.address, 1)
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, communityMenber1.address, 2)
          .to.emit(synNft, 'Transfer')
          .withArgs(addr0, communityMenber2.address, 3)

    })

  })


})
