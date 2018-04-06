export function ether (n) {
  return new web3.BigNumber(web3.toWei(n, 'ether'));
}

export function finney (n) {
  return new web3.BigNumber(web3.toWei(n, 'finney'));
}

export function szabo (n) {
  return new web3.BigNumber(web3.toWei(n, 'szabo'));
}