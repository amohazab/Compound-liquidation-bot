We tried to use compound protocol with the dy/dx flash loan smart contract.
Obviously flash loan is going to boost the payoff since in some cases you need a lot of money to implement the liquidation. I think the best flashloan provider is dy/dx since their rate is really negligible. It is 2 wei which is technically nothing.
for the compound part i used https://cryptomarketpool.com/compound-finance-liquidation-bot/
which was a very intuitive illustration.
And for the flashloan part, I think the most straight forward way is to use money-lego, https://money-legos.studydefi.com/#/dydx.
Though big liquidation opportunities are not very common, we can increase the chance by observing diferent lending protocols such as Compound, Aave, Uniswap, dy/dx and many more.

Obviously the best way to audit them is not onchain since you have to use Infura node and there is a limit on it, but it would be much more efficient to check the log events to get the necessary data.
