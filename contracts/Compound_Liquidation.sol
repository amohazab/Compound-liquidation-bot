pragma solidity ^0.8.6;

//ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

//Compound cERC20 interface
interface CErc20 {
  function balanceOf(address) external view returns (uint);
  function mint(uint) external returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function supplyRatePerBlock() external returns (uint);
  function balanceOfUnderlying(address) external returns (uint);
  function redeem(uint) external returns (uint);
  function redeemUnderlying(uint) external returns (uint);
  function borrow(uint) external returns (uint);
  function borrowBalanceCurrent(address) external returns (uint);
  function borrowRatePerBlock() external view returns (uint);
  function repayBorrow(uint) external returns (uint);
  function liquidateBorrow(
    address borrower,
    uint amount,
    address collateral
  ) external returns (uint);
}

//Compound CETH interface
interface CEth {
  function balanceOf(address) external view returns (uint);
  function mint() external payable;
  function exchangeRateCurrent() external returns (uint);
  function supplyRatePerBlock() external returns (uint);
  function balanceOfUnderlying(address) external returns (uint);
  function redeem(uint) external returns (uint);
  function redeemUnderlying(uint) external returns (uint);
  function borrow(uint) external returns (uint);
  function borrowBalanceCurrent(address) external returns (uint);
  function borrowRatePerBlock() external view returns (uint);
  function repayBorrow() external payable;
}

//Compound Comptroller interface
interface Comptroller {
  function markets(address)
    external
    view
    returns (
      bool,
      uint,
      bool
    );
  function enterMarkets(address[] calldata) external returns (uint[] memory);
  function getAccountLiquidity(address)
    external
    view
    returns (
      uint,
      uint,
      uint
    );
  function closeFactorMantissa() external view returns (uint);
  function liquidationIncentiveMantissa() external view returns (uint);
  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint actualRepayAmount
  ) external view returns (uint, uint);
}

//Compound price feed interface
interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

contract performLiquidationOnCompound {

//set several state variables
   IERC20 public token;
   CErc20 public ctoken;
   Comptroller public comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
   PriceFeed public priceFeed = PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1);

//set token
    function settoken(address _token) public {
        token = IERC20(_token);
    }


//set ctoken - Compound token
    function setctoken(address _ctoken) public {
        ctoken = CErc20(_ctoken);
    }


  //call on the comptroller contract
  //close factor is the maximum percentage of borrowed tokens that can be repayed
  //a percent ranging from 0% to 100% of a liquidatable account’s borrow.
  //if you want to view this as a percentage divide the result by 10**18 
  function closeFactor() external view returns (uint) {
      return comptroller.closeFactorMantissa();
  }

  //call on the comptroller contract
  //liquidation incentive is your incentive amount to liquidate the contract
  //you are rewarded with a portion of the token that was supplied as collateral
  //you receive the collateral at a discount aka your incentive
  function liquidationIncentive() external view returns (uint) {
    return comptroller.liquidationIncentiveMantissa();
  }

  //call on the comptroller contract
  //get the exact amount of collateral to be liquidated
  function amountToBeLiquidatedSieze(address _cToken, address _cTokenCollateral, uint _actualRepayAmount) external view returns (uint) {
    (uint error, uint cTokenCollateralAmount) = comptroller
    .liquidateCalculateSeizeTokens(
      _cToken,
      _cTokenCollateral,
      _actualRepayAmount
    );
    require(error == 0, "error");
    return cTokenCollateralAmount;
  }

  //Call liquidate borrow on the cToken contract
  //liquidate takes 3 parameters
  //the address of the borrower, amount that you will repay, and ctoken address that we will receive in return for liquidating the account  
  function liquidate(address _borrower, uint _repayAmount, address _cTokenCollateral) external {
  //transfer the token borrowed from mesage.sender to this contract
    token.transferFrom(msg.sender, address(this), _repayAmount);
  //then approve the ctoken repay amount to be spent
    token.approve(address(ctoken), _repayAmount);
  //call liquidate borrow in the ctoken contract and passing in the necessary parameters using a require statement
  //a successful liquidate borrow will return o
  //if the call is not successful liquidation failed will display
    require(ctoken.liquidateBorrow(_borrower, _repayAmount, _cTokenCollateral) == 0, "liquidation failed");
  }

  function getPriceFeed(address _ctoken) external view returns (uint) {
    return priceFeed.getUnderlyingPrice(_ctoken);
  }

}