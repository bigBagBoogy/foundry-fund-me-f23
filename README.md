# some commands used frequently

forge script script/DeployFundMe.s.sol

forge test --mt <nameOfTest> -vvv

forge test -vvv --fork-url $SEPOLIA_RPC_URL

forge test --match-test testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL

or:
forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL

source .env

just for testing "source .env -> $echo $SEPOLIA_RPC_URL

forge coverage --fork-url $SEPOLIA_RPC_URL

forge test -vvv --fork-url $SEPOLIA_RPC_URL

# Github reminder

git init
git branch -M main
git add .
git remote add origin https://github.com/bigBagBoogy/foundry-fund-me-f23.git
git commit -m "first commit"
git push -u origin main

# instant push copy paste all below in one go:

git init
git branch -M main
git add .
git commit -m "test added"
git push -u origin main

forge less used commands:

forge inspect <nameOfContract> storageLayout
