
pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;

import "./Compound_Liquidation.sol";
import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DydxFlashloaner is ICallee, DydxFlashloanBase, Compound_Liquidation {

    struct MyCustomData {
        address token;
        uint256 repayAmount;
        address borrower;
        uint liqRepayAmount;
        address cTokenCollateral;
    }

    // This is the function that will be called postLoan
    // i.e. Encode the logic to handle your flashloaned funds here
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));
        uint256 balOfLoanedToken = IERC20(mcd.token).balanceOf(address(this));

        token = IERC20(mcd.token);
        ctokenCollateral = CErc20(cTokenCollateral);

        // Note that you can ignore the line below
        // if your dydx account (this contract in this case)
        // has deposited at least ~2 Wei of assets into the account
        // to balance out the collaterization ratio
        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );

        liquidate(mcd.borrower, mcd.liqRepayAmount, cTokenCollateral);

        // TODO: Encode your logic here
        // E.g. arbitrage, liquidate accounts, etc






    }

    function initiateFlashLoan(address _solo, address _token, uint256 _amount , address _borrower, uint _liqRepayAmount, address _cTokenCollateral)
        external
    {
        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            // Encode MyCustomData for callFunction
            abi.encode(MyCustomData({token: _token, repayAmount: repayAmount , borrower: _borrower , liqRepayAmount: _liqRepayAmount , cTokenCollateral: _cTokenCollateral }))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }
}

Flashloan Initiation (JavaScript)

Once you've deployed the contract, you can then call initiate the flashloan using the example below. Note that you can MyCustomData can be anything you desire, and if you would like to encode the data from the JS side, you can use ethers.utils.defaultAbiCoder.

const dydxFlashloanerContract = new ethers.Contract(
  dydxFlashloanerAddress,
  def.abi,
  wallet
);

const main = async () => {
  const tx = await dydxFlashloanerContract.initiateFlashLoan(
    legos.dydx.soloMargin.address,
    legos.erc20.weth.address, // Wanna take out a WETH loan
    ethers.utils.parseEther("10"),      // Wanna loan 10 WETH
    {
      gasLimit: 6000000,
    }
  );
  await tx.wait();
};